import 'dart:async';
import 'dart:io';

import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
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
  const ActivityUploadConfig({required this.endpoint, required this.fieldName});

  /// Build from [ApiEndpoints] so a custom `AppConfig.apiBasePath` is
  /// reflected in the upload endpoint path.
  factory ActivityUploadConfig.fromEndpoints(ApiEndpoints endpoints) {
    return ActivityUploadConfig(
      endpoint: endpoints.activityUploadEndpoint,
      fieldName: ApiConstants.activityUploadFieldName,
    );
  }

  final String endpoint;
  final String fieldName;

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
  }) : _config = config,
       _uploadFile = uploadFile,
       _retryPolicy = retryPolicy ?? const ActivityUploadRetryPolicy();

  final ActivityUploadConfig? _config;
  final ActivityFileUploader? _uploadFile;
  final ActivityUploadRetryPolicy _retryPolicy;
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
      return;
    }
    if (response.statusCode == 401) {
      throw const AppException(AppErrorCode.sessionExpired);
    }

    throw AppException(
      AppErrorCode.activityUploadFailed,
      details: 'HTTP ${response.statusCode}',
    );
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
    final current = persisted;
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
          autoRetryEligible: _isTransient(error),
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
  /// response or network-level I/O error). Auth failures, missing GPX, and
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
        error.code == AppErrorCode.transientAuthUnavailable) {
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
