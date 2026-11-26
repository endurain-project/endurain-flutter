import 'dart:async';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/services/activity_upload_retry_policy.dart';

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

/// Controls how long `ActivityUploadService` waits for a `202 Accepted`
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

/// Follows a `202 Accepted` upload's ingestion job to completion.
class IngestionJobPoller {
  const IngestionJobPoller({
    required IngestionJobFetcher fetchJob,
    IngestionPollPolicy policy = const IngestionPollPolicy(),
  }) : _fetch = fetchJob,
       _policy = policy;

  final IngestionJobFetcher _fetch;
  final IngestionPollPolicy _policy;

  /// Polls the ingestion job until it finishes.
  ///
  /// Returns on success. Throws [AppErrorCode.activityUploadFailed] with the
  /// job's `error_code` as details when the job fails (permanent, not retried
  /// automatically), or with a [TimeoutException] cause when it is still
  /// running after the poll budget (transient, retried automatically).
  Future<void> awaitCompletion(
    String endpoint, {
    Duration? firstWait,
    String? expectedOrigin,
    String? expectedProfileId,
  }) async {
    final fetch = _fetch;
    final polls = _policy.maxPolls.clamp(1, 1 << 20);
    var nextWait = firstWait;

    for (var poll = 0; poll < polls; poll++) {
      // The server says when to read the job, also before the first read.
      await _policy.delay(poll, _policy.waitFor(nextWait));
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
        if (ActivityUploadFailures.isTransientIoError(error)) {
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
      return ActivityUploadFailures.isTransientIoError(cause);
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
}

enum _JobOutcome { succeeded, failed, running }
