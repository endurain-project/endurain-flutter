import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/api_client.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:http/http.dart' as http;

typedef ActivityFileUploader =
    Future<http.StreamedResponse> Function(
      String endpoint,
      String filePath,
      String fieldName,
    );

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

  /// Default contract matching the Endurain server upload endpoint
  /// (`POST /api/v1/activities/create/upload` with a `file` multipart field).
  const ActivityUploadConfig.endurain()
    : endpoint = ApiConstants.activityUploadEndpoint,
      fieldName = ApiConstants.activityUploadFieldName;

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
  });

  final String filePath;
  final ActivityType activityType;
}

class ActivityUploadService {
  ActivityUploadService({
    ApiClient? apiClient,
    ActivityUploadConfig? config,
    ActivityFileUploader? uploadFile,
    ActivityUploadRetryPolicy? retryPolicy,
  }) : _config = config,
       _uploadFile = uploadFile ?? (apiClient ?? ApiClient()).uploadFile,
       _retryPolicy = retryPolicy ?? const ActivityUploadRetryPolicy();

  final ActivityUploadConfig? _config;
  final ActivityFileUploader _uploadFile;
  final ActivityUploadRetryPolicy _retryPolicy;

  bool get isConfigured => _config?.isConfigured ?? false;

  Future<void> uploadGpx(ActivityUploadRequest request) async {
    final config = _config;
    if (config == null || !config.isConfigured) {
      throw const AppException(AppErrorCode.activityUploadNotConfigured);
    }

    late final http.StreamedResponse response;
    try {
      response = await _uploadFile(
        config.endpoint,
        request.filePath,
        config.fieldName,
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
  /// success.
  Future<LocalActivityRecord> performUploadAttempt({
    required LocalActivityRecord record,
    required LocalActivityRepository repository,
    ActivityRetentionSettingsRepository? retentionRepository,
    DateTime Function()? now,
  }) async {
    final clock = now ?? DateTime.now;
    final attemptedAt = clock().toUtc();

    LocalActivityRecord updated = record.copyWith(
      uploadStatus: LocalActivityUploadStatus.pending,
      updatedAt: attemptedAt,
      lastUploadAttemptAt: attemptedAt,
      lastUploadErrorCode: null,
    );
    await repository.upsert(updated);

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
          ),
        );

        final uploadedAt = clock().toUtc();
        updated = updated.copyWith(
          uploadStatus: LocalActivityUploadStatus.uploaded,
          updatedAt: uploadedAt,
          uploadedAt: uploadedAt,
          lastUploadAttemptAt: attemptedAt,
          lastUploadErrorCode: null,
        );
        await repository.upsert(updated);

        if (!await _shouldRetainUploadedGpx(retentionRepository)) {
          await repository.deleteGpx(updated);
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
        );
        await repository.upsert(failedRecord);
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
  static bool _isTransient(Object error) {
    if (error is! AppException) {
      return true;
    }
    if (error.code != AppErrorCode.activityUploadFailed) {
      return false;
    }
    // Network-level error (no HTTP status): transient.
    if (error.cause != null) {
      return true;
    }
    // HTTP 5xx: transient. HTTP 4xx: permanent.
    final details = error.details;
    if (details != null && details.startsWith('HTTP 5')) {
      return true;
    }
    return false;
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
}
