import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:http/http.dart' as http;

/// Uploads a GPX file to the activity import endpoint.
///
/// The single injection seam for the transport. In production this is
/// `ApiClient.uploadFile` (token-refreshing, profile-scoped multipart); tests
/// pass a fake. The named parameters mirror `ApiClient.uploadFile` so the
/// method tear-off is a drop-in, preserving the idempotency key and the
/// origin/profile scoping.
typedef ActivityFileUploader = Future<http.StreamedResponse> Function(
  String endpoint,
  String filePath,
  String fieldName, {
  String? idempotencyKey,
  String? expectedOrigin,
  String? expectedProfileId,
});

/// One read of a job: its decoded JSON and the server's `Retry-After`, the
/// wait it asks for before the next read (absent once the job is finished).
typedef IngestionJobRead = ({Map<String, dynamic> job, Duration? retryAfter});

/// Reads the job at [endpoint] (`GET /jobs/{job_id}`).
///
/// In production this wraps `ApiClient.getJsonObjectWithHeaders`
/// (token-refreshing, profile-scoped). Required to follow a `202 Accepted`
/// upload to completion.
typedef IngestionJobFetcher = Future<IngestionJobRead> Function(
  String endpoint, {
  String? expectedOrigin,
  String? expectedProfileId,
});

/// Controls how long [ActivityUploadService] waits for a `202 Accepted`
/// upload's ingestion job to finish before giving up.
///
/// A job still unfinished after [maxPolls] checks is treated as a transient
/// failure: the record stays retryable and the retry replays the upload with
/// the same idempotency key, which the server de-duplicates.
///
/// Between checks it waits the `Retry-After` the server sent, bounded by
/// [minWait] and [maxWait], or [defaultWait] when there was none.
class IngestionPollPolicy {
  const IngestionPollPolicy({
    this.maxPolls = 30,
    this.defaultWait = const Duration(seconds: 2),
    this.minWait = const Duration(seconds: 1),
    this.maxWait = const Duration(seconds: 10),
    Future<void> Function(int poll, Duration wait)? delay,
  }) : delay = delay ?? _defaultDelay;

  final int maxPolls;
  final Duration defaultWait;
  final Duration minWait;
  final Duration maxWait;

  /// Waits `wait` before check number `poll`; replaced in tests.
  final Future<void> Function(int poll, Duration wait) delay;

  static Future<void> _defaultDelay(int poll, Duration wait) =>
      Future.delayed(wait);

  /// The wait before the next check, from the server's [retryAfter].
  Duration waitFor(Duration? retryAfter) {
    final wait = retryAfter ?? defaultWait;
    if (wait < minWait) return minWait;
    if (wait > maxWait) return maxWait;
    return wait;
  }
}

/// Controls how many times [ActivityUploadService.performUploadAttempt]
/// retries transient failures and how long it waits between attempts.
///
/// Set [maxAttempts] to `1` (the default) to disable automatic retry and keep
/// the same single-attempt behaviour as before. Set it to a higher value for
/// post-recording uploads that benefit from silent recovery.
///
/// Inject a no-op [delay] in tests to avoid real sleeps.
class ActivityUploadRetryPolicy {
  const ActivityUploadRetryPolicy({
    this.maxAttempts = 1,
    Future<void> Function(int attempt)? delay,
  }) : delay = delay ?? _defaultDelay;

  final int maxAttempts;
  final Future<void> Function(int attempt) delay;

  static Future<void> _defaultDelay(int attempt) =>
      Future.delayed(const Duration(seconds: 2));
}

class ActivityUploadConfig {
  const ActivityUploadConfig({
    required this.endpoint,
    required this.fieldName,
    this.ingestionJobPath = _defaultJobPath,
    this.isJobPath = _defaultIsJobPath,
  });

  static String _defaultJobPath(String jobId) =>
      ApiEndpoints.defaults.jobEndpoint(jobId);

  static bool _defaultIsJobPath(String path) =>
      ApiEndpoints.defaults.isJobPath(path);

  /// Build from [ApiEndpoints] so a custom `AppConfig.apiBasePath` is
  /// reflected in the upload endpoint path.
  factory ActivityUploadConfig.fromEndpoints(ApiEndpoints endpoints) {
    return ActivityUploadConfig(
      endpoint: endpoints.activityUploadEndpoint,
      fieldName: ApiConstants.activityUploadFieldName,
      ingestionJobPath: endpoints.jobEndpoint,
      isJobPath: endpoints.isJobPath,
    );
  }

  final String endpoint;
  final String fieldName;

  /// Builds the path of a job (`GET /jobs/{job_id}`) from its id.
  final String Function(String jobId) ingestionJobPath;

  /// Whether a server-supplied `Content-Location` is a job path this client
  /// may poll with its bearer token.
  final bool Function(String path) isJobPath;

  String ingestionJobEndpoint(String jobId) => ingestionJobPath(jobId);

  bool get isConfigured {
    return endpoint.trim().isNotEmpty && fieldName.trim().isNotEmpty;
  }
}

class ActivityUploadRequest {
  const ActivityUploadRequest({
    required this.filePath,
    required this.activityType,
    this.idempotencyKey,
    this.expectedOrigin,
    this.expectedProfileId,
  });

  final String filePath;
  final ActivityType activityType;

  /// Stable key sent with the upload so the server can de-duplicate retried
  /// uploads of the same activity. Typically the local activity id.
  final String? idempotencyKey;
  final String? expectedOrigin;
  final String? expectedProfileId;
}

class ActivityUploadService {
  ActivityUploadService({
    ActivityUploadConfig? config,
    ActivityFileUploader? uploadFile,
    ActivityUploadRetryPolicy? retryPolicy,
    IngestionJobFetcher? fetchIngestionJob,
    IngestionPollPolicy? pollPolicy,
    Future<ConnectionProfile?> Function()? activeConnectionProfile,
  }) : _config = config,
       _uploadFile = uploadFile,
       _retryPolicy = retryPolicy ?? const ActivityUploadRetryPolicy(),
       _fetchIngestionJob = fetchIngestionJob,
       _pollPolicy = pollPolicy ?? const IngestionPollPolicy(),
       _activeConnectionProfile = activeConnectionProfile;

  final ActivityUploadConfig? _config;
  final ActivityFileUploader? _uploadFile;
  final ActivityUploadRetryPolicy _retryPolicy;
  final IngestionJobFetcher? _fetchIngestionJob;
  final IngestionPollPolicy _pollPolicy;
  final Future<ConnectionProfile?> Function()? _activeConnectionProfile;
  final Map<String, Future<LocalActivityRecord>> _inFlightAttempts = {};

  bool get isConfigured =>
      (_config?.isConfigured ?? false) && _uploadFile != null;

  Future<void> uploadGpx(ActivityUploadRequest request) async {
    final config = _config;
    final uploader = _uploadFile;
    if (config == null || !config.isConfigured || uploader == null) {
      throw const AppException(AppErrorCode.activityUploadNotConfigured);
    }

    late final http.StreamedResponse response;
    try {
      response = await uploader(
        config.endpoint,
        request.filePath,
        config.fieldName,
        idempotencyKey: request.idempotencyKey,
        expectedOrigin: request.expectedOrigin,
        expectedProfileId: request.expectedProfileId,
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.activityUploadFailed, cause: error);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final job = await _readAcceptedJob(response, config);
      if (job != null && _fetchIngestionJob != null) {
        await _awaitIngestion(
          job.endpoint,
          firstWait: job.retryAfter,
          expectedOrigin: request.expectedOrigin,
          expectedProfileId: request.expectedProfileId,
        );
      }
      return;
    }
    if (response.statusCode == 401) {
      throw const AppException(AppErrorCode.sessionExpired);
    }
    final problem = await _readProblem(response);
    if (response.statusCode == 409 && !_isKeyConflict(problem)) {
      // The server's cap on open uploads (10 per user). Not worth an
      // immediate retry, but the next drain uploads it once a job finishes.
      throw const AppException(
        AppErrorCode.activityUploadFailed,
        details: uploadLimitDetails,
      );
    }

    throw AppException(
      AppErrorCode.activityUploadFailed,
      details: switch (response.statusCode) {
        403 when problem.type.contains('mfa-enrolment-required') =>
          mfaEnrolmentRequiredDetails,
        413 => fileTooLargeDetails,
        415 => unsupportedFileTypeDetails,
        _ => 'HTTP ${response.statusCode}',
      },
    );
  }

  /// [AppException.details] of an upload the server refused because an
  /// administrator requires two-step verification the account has not set up.
  static const String mfaEnrolmentRequiredDetails = 'mfa_enrolment_required';

  /// [AppException.details] of a file over the server's size limit (`413`).
  static const String fileTooLargeDetails = 'file_too_large';

  /// [AppException.details] of a file type the server does not accept (`415`).
  static const String unsupportedFileTypeDetails = 'unsupported_file_type';

  /// [AppException.details] of an upload refused at the server's cap on open
  /// uploads; such a record stays eligible for the next automatic retry.
  static const String uploadLimitDetails = 'upload_limit';

  /// Reads the RFC 9457 problem document of a refused upload; both fields are
  /// empty when the body is missing or not a problem document.
  static Future<({String type, String detail})> _readProblem(
    http.StreamedResponse response,
  ) async {
    try {
      final body = json.decode(await response.stream.bytesToString());
      if (body is Map) {
        return (
          type: body['type'] is String ? body['type'] as String : '',
          detail: body['detail'] is String ? body['detail'] as String : '',
        );
      }
    } catch (_) {
      // Not JSON: no problem to read.
    }
    return (type: '', detail: '');
  }

  /// Whether a `409` refused the `Idempotency-Key` itself (the same key sent
  /// with a different file), which no retry can fix.
  ///
  /// Both `409`s of the upload route carry `urn:endurain:error:conflict`; only
  /// the problem `detail` tells them apart, so any other `409` is read as the
  /// cap on open uploads.
  static bool _isKeyConflict(({String type, String detail}) problem) =>
      problem.detail.contains('Idempotency-Key');

  /// Reads the job a `202 Accepted` names: the path to poll (the
  /// `Content-Location` when it is a job path on this API, else built from the
  /// body's `id`) and the first `Retry-After`.
  ///
  /// Returns `null` for any other response or one that names no job (servers
  /// that import inline), which callers treat as already complete.
  static Future<({String endpoint, Duration? retryAfter})?> _readAcceptedJob(
    http.StreamedResponse response,
    ActivityUploadConfig config,
  ) async {
    if (response.statusCode != 202) {
      return null;
    }
    final retryAfter = parseRetryAfter(
      response.headers[ApiConstants.retryAfterHeader],
    );
    final location = response.headers[ApiConstants.contentLocationHeader];
    if (location != null && config.isJobPath(location)) {
      await response.stream.drain<void>();
      return (endpoint: location, retryAfter: retryAfter);
    }
    try {
      final body = json.decode(await response.stream.bytesToString());
      final id = body is Map ? body['id'] : null;
      if (id is String && id.isNotEmpty) {
        return (
          endpoint: config.ingestionJobEndpoint(id),
          retryAfter: retryAfter,
        );
      }
    } catch (_) {
      // No readable job: treated as finished, like an inline import.
    }
    return null;
  }

  /// Parses a `Retry-After` given in seconds (the form Endurain sends).
  static Duration? parseRetryAfter(String? value) {
    final seconds = int.tryParse(value?.trim() ?? '');
    return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
  }

  /// Polls the ingestion job until it finishes.
  ///
  /// Returns on success. Throws [AppErrorCode.activityUploadFailed] with the
  /// job's `error_code` as details when the job fails (permanent, not retried
  /// automatically), or with a [TimeoutException] cause when it is still
  /// running after the poll budget (transient, retried automatically).
  Future<void> _awaitIngestion(
    String endpoint, {
    Duration? firstWait,
    String? expectedOrigin,
    String? expectedProfileId,
  }) async {
    final fetch = _fetchIngestionJob!;
    final polls = _pollPolicy.maxPolls.clamp(1, 1 << 20);
    var nextWait = firstWait;

    for (var poll = 0; poll < polls; poll++) {
      // The server says when to read the job, also before the first read.
      await _pollPolicy.delay(poll, _pollPolicy.waitFor(nextWait));
      nextWait = null;
      final Map<String, dynamic> job;
      try {
        final read = await fetch(
          endpoint,
          expectedOrigin: expectedOrigin,
          expectedProfileId: expectedProfileId,
        );
        job = read.job;
        nextWait = read.retryAfter;
      } on AppException catch (error) {
        // A transient status check failure must not abandon a job that may
        // still succeed; auth and permanent (4xx) failures end the attempt.
        if (_isTransientPollError(error)) {
          continue;
        }
        rethrow;
      } catch (error) {
        if (_isTransientIoError(error)) {
          continue;
        }
        throw AppException(AppErrorCode.activityUploadFailed, cause: error);
      }

      switch (_classifyJob(job)) {
        case _JobOutcome.succeeded:
          return;
        case _JobOutcome.failed:
          final code = job['error_code'];
          throw AppException(
            AppErrorCode.activityUploadFailed,
            details: code is String ? code : null,
          );
        case _JobOutcome.running:
          continue;
      }
    }

    throw AppException(
      AppErrorCode.activityUploadFailed,
      cause: TimeoutException('Ingestion job $endpoint did not finish'),
    );
  }

  /// Whether a failed job status check is worth polling through: a request
  /// timeout, a recognized I/O failure, or a 5xx response.
  static bool _isTransientPollError(AppException error) {
    if (error.code == AppErrorCode.requestTimeout) {
      return true;
    }
    if (error.cause case final cause?) {
      return _isTransientIoError(cause);
    }
    final status = error.statusCode;
    return status != null && status >= 500;
  }

  /// Classifies a job status: `queued` and `running` are still running,
  /// `failed` is terminal failure, and `succeeded` is success unless any file
  /// failed. An unknown status keeps polling so a status added by a newer
  /// server cannot be mistaken for success.
  static _JobOutcome _classifyJob(Map<String, dynamic> job) {
    final failedFiles = job['files_failed'];
    return switch (job['status']) {
      'failed' => _JobOutcome.failed,
      'succeeded' when failedFiles is num && failedFiles > 0 =>
        _JobOutcome.failed,
      'succeeded' => _JobOutcome.succeeded,
      _ => _JobOutcome.running,
    };
  }

  /// Performs a complete upload workflow for [record]:
  /// pending → upsert → GPX read → upload → uploaded → retention cleanup.
  ///
  /// On failure the record is persisted as [LocalActivityUploadStatus.failed]
  /// and the exception is re-thrown so callers can update UI state.
  ///
  /// Transient failures (5xx responses and network-level errors) are retried
  /// up to [ActivityUploadRetryPolicy.maxAttempts] times before giving up.
  ///
  /// Returns the final [LocalActivityRecord] with an `uploaded` status on
  /// success. If the server upload succeeds but post-upload GPX cleanup fails,
  /// the record remains `uploaded` and carries
  /// [AppErrorCode.activityGpxCleanupFailed] in [LocalActivityRecord.lastUploadErrorCode].
  Future<LocalActivityRecord> performUploadAttempt({
    required LocalActivityRecord record,
    required LocalActivityRepository repository,
    ActivityRetentionSettingsRepository? retentionRepository,
    DateTime Function()? now,
  }) {
    final existing = _inFlightAttempts[record.id];
    if (existing != null) {
      return existing;
    }
    final attempt =
        _performUploadAttempt(
          record: record,
          repository: repository,
          retentionRepository: retentionRepository,
          now: now,
        ).whenComplete(() {
          _inFlightAttempts.remove(record.id);
        });
    _inFlightAttempts[record.id] = attempt;
    return attempt;
  }

  static bool _lacksConnection(LocalActivityRecord record) =>
      record.connectionOrigin == null && record.connectionProfileId == null;

  /// Activities recorded while signed out carry no origin/profile. When the
  /// user has since signed in, claim just this record for the active
  /// connection so a manual upload or retry works without a restart. Other
  /// guest records stay unassigned until their own upload or the queue drain.
  Future<LocalActivityRecord> _claimForActiveProfile(
    LocalActivityRecord record,
    LocalActivityRepository repository,
    DateTime Function() clock,
  ) async {
    final profileProvider = _activeConnectionProfile;
    if (profileProvider == null) {
      return record;
    }
    final profile = await profileProvider();
    if (profile == null) {
      return record;
    }
    await repository.bindRecordToProfile(
      id: record.id,
      origin: profile.origin,
      profileId: profile.id,
      updatedAt: clock().toUtc(),
    );
    return await repository.get(record.id) ?? record;
  }

  Future<LocalActivityRecord> _performUploadAttempt({
    required LocalActivityRecord record,
    required LocalActivityRepository repository,
    ActivityRetentionSettingsRepository? retentionRepository,
    DateTime Function()? now,
  }) async {
    final persisted = await repository.get(record.id);
    if (persisted == null) {
      throw const AppException(AppErrorCode.activityLocalActivityNotFound);
    }
    var current = persisted;
    if (current.uploadStatus != LocalActivityUploadStatus.uploaded &&
        _lacksConnection(current)) {
      current = await _claimForActiveProfile(
        current,
        repository,
        now ?? DateTime.now,
      );
    }
    if (current.uploadStatus == LocalActivityUploadStatus.uploaded) {
      if (current.gpxCleanupPending) {
        return _retryUploadedGpxCleanup(
          record: current,
          repository: repository,
          retentionRepository: retentionRepository,
          now: now ?? DateTime.now,
        );
      }
      return current;
    }
    final connectionOrigin = current.connectionOrigin;
    if (connectionOrigin == null || connectionOrigin.isEmpty) {
      throw const AppException(AppErrorCode.notAuthenticated);
    }
    final connectionProfileId = current.connectionProfileId;
    if (connectionProfileId == null || connectionProfileId.isEmpty) {
      throw const AppException(AppErrorCode.notAuthenticated);
    }
    final clock = now ?? DateTime.now;
    final attemptedAt = clock().toUtc();

    LocalActivityRecord updated = current.copyWith(
      uploadStatus: LocalActivityUploadStatus.pending,
      updatedAt: attemptedAt,
      lastUploadAttemptAt: attemptedAt,
      lastUploadErrorCode: null,
      autoRetryEligible: true,
    );
    if (!await repository.updateIfPresent(updated)) {
      throw const AppException(AppErrorCode.activityLocalActivityNotFound);
    }

    final maxAttempts = _retryPolicy.maxAttempts.clamp(1, 1 << 20);
    Object? lastError;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        await _retryPolicy.delay(attempt);
      }
      try {
        if (!isConfigured) {
          throw const AppException(AppErrorCode.activityUploadNotConfigured);
        }
        final filePath = await repository.readGpxFilePath(updated);
        await uploadGpx(
          ActivityUploadRequest(
            filePath: filePath,
            activityType: updated.activityType,
            idempotencyKey: updated.effectiveIdempotencyKey,
            expectedOrigin: updated.connectionOrigin,
            expectedProfileId: updated.connectionProfileId,
          ),
        );

        final uploadedAt = clock().toUtc();
        updated = updated.copyWith(
          uploadStatus: LocalActivityUploadStatus.uploaded,
          updatedAt: uploadedAt,
          uploadedAt: uploadedAt,
          lastUploadAttemptAt: attemptedAt,
          lastUploadErrorCode: null,
          autoRetryEligible: false,
        );
        if (!await repository.updateIfPresent(updated)) {
          throw const AppException(AppErrorCode.activityLocalActivityNotFound);
        }

        final cleanupError = await _cleanupUploadedGpx(
          record: updated,
          repository: repository,
          retentionRepository: retentionRepository,
        );
        if (cleanupError != null) {
          updated = updated.copyWith(
            updatedAt: clock().toUtc(),
            lastUploadErrorCode: cleanupError.code,
            gpxCleanupPending: true,
          );
          await repository.updateIfPresent(updated);
        }

        return updated;
      } catch (error) {
        lastError = error;
        if (attempt < maxAttempts - 1 && _isTransient(error)) {
          continue;
        }
        final failedRecord = updated.copyWith(
          uploadStatus: LocalActivityUploadStatus.failed,
          updatedAt: clock().toUtc(),
          lastUploadAttemptAt: attemptedAt,
          lastUploadErrorCode: _safeUploadErrorCode(error),
          autoRetryEligible: _isTransient(error) || _isUploadLimit(error),
        );
        await repository.updateIfPresent(failedRecord);
        rethrow;
      }
    }

    // Unreachable: loop always returns or rethrows inside the catch block.
    // This satisfies Dart's control flow analysis.
    throw lastError!;
  }

  /// Returns true if [error] represents a failure worth retrying (5xx
  /// response, network-level I/O error, or secure storage temporarily
  /// unreadable). Auth failures, missing GPX, and
  /// configuration errors are not transient.
  ///
  /// An unexpected non-[AppException] (e.g. a `TypeError`/`StateError` from a
  /// programming bug) is only retried when it is a known I/O/network failure;
  /// genuine bugs fail fast instead of burning the retry budget and masking
  /// the defect.
  static bool _isTransient(Object error) {
    if (error is! AppException) {
      return _isTransientIoError(error);
    }
    if (error.code == AppErrorCode.requestTimeout ||
        error.code == AppErrorCode.transientAuthUnavailable ||
        error.code == AppErrorCode.secureStorageReadFailed) {
      return true;
    }
    if (error.code != AppErrorCode.activityUploadFailed) {
      return false;
    }
    // Only known network/I/O causes are transient. Unexpected adapter or
    // parsing failures require manual review instead of looping on resume.
    if (error.cause case final cause?) {
      return _isTransientIoError(cause);
    }
    // HTTP 5xx: transient. HTTP 4xx: permanent.
    final details = error.details;
    if (details != null && details.startsWith('HTTP 5')) {
      return true;
    }
    return false;
  }

  /// Whether [error] is the server's cap on open uploads: retried at the next
  /// drain, not at once.
  static bool _isUploadLimit(Object error) =>
      error is AppException &&
      error.code == AppErrorCode.activityUploadFailed &&
      error.details == uploadLimitDetails;

  /// Whether [error] is a known transient I/O/network failure.
  static bool _isTransientIoError(Object error) {
    return error is SocketException ||
        error is http.ClientException ||
        error is TimeoutException ||
        error is HttpException;
  }

  /// Maps any exception to a typed [AppErrorCode] safe for persistence.
  static AppErrorCode _safeUploadErrorCode(Object error) {
    return error is AppException
        ? error.code
        : AppErrorCode.activityUploadFailed;
  }

  static Future<bool> _shouldRetainUploadedGpx(
    ActivityRetentionSettingsRepository? repo,
  ) async {
    return await repo?.isRetainUploadedGpxEnabled() ?? true;
  }

  static Future<AppException?> _cleanupUploadedGpx({
    required LocalActivityRecord record,
    required LocalActivityRepository repository,
    ActivityRetentionSettingsRepository? retentionRepository,
  }) async {
    try {
      if (await _shouldRetainUploadedGpx(retentionRepository)) {
        return null;
      }
      await repository.deleteGpx(record);
      return null;
    } on AppException catch (error) {
      return AppException(AppErrorCode.activityGpxCleanupFailed, cause: error);
    } catch (error) {
      return AppException(AppErrorCode.activityGpxCleanupFailed, cause: error);
    }
  }

  Future<LocalActivityRecord> _retryUploadedGpxCleanup({
    required LocalActivityRecord record,
    required LocalActivityRepository repository,
    required ActivityRetentionSettingsRepository? retentionRepository,
    required DateTime Function() now,
  }) async {
    final cleanupError = await _cleanupUploadedGpx(
      record: record,
      repository: repository,
      retentionRepository: retentionRepository,
    );
    final updated = record.copyWith(
      updatedAt: now().toUtc(),
      gpxCleanupPending: cleanupError != null,
      lastUploadErrorCode: cleanupError?.code,
    );
    await repository.updateIfPresent(updated);
    return updated;
  }
}

enum _JobOutcome { succeeded, failed, running }
