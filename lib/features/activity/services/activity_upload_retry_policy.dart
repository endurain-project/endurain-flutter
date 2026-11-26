import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:endurain/core/models/app_exception.dart';
import 'package:http/http.dart' as http;

/// Controls how many times `ActivityUploadService.performUploadAttempt`
/// retries transient failures and how long it waits between attempts.
///
/// Set [maxAttempts] to `1` (the default) to disable automatic retry and keep
/// the same single-attempt behaviour as before. Set it to a higher value for
/// post-recording uploads that benefit from silent recovery.
///
/// Between attempts it waits [retryDelay], or longer when the failed response
/// carried a `Retry-After`. A `Retry-After` beyond [maxRetryAfter] is not
/// waited out in-process: the attempt ends there and the record stays
/// auto-retry-eligible for the next queue drain (resume, reconnect).
///
/// Inject a no-op [delay] in tests to avoid real sleeps.
class ActivityUploadRetryPolicy {
  const ActivityUploadRetryPolicy({
    this.maxAttempts = 1,
    this.retryDelay = const Duration(seconds: 2),
    this.maxRetryAfter = const Duration(seconds: 60),
    Future<void> Function(int attempt, Duration wait)? delay,
  }) : delay = delay ?? _defaultDelay;

  final int maxAttempts;

  /// The wait between attempts when the server did not ask for a longer one.
  final Duration retryDelay;

  /// The longest server-requested `Retry-After` waited in-process. Longer
  /// requests end the attempt instead, so a busy server cannot hold the
  /// upload queue (or a user's manual retry) for minutes while the app may
  /// be suspended anyway.
  final Duration maxRetryAfter;

  /// Waits `wait` before attempt number `attempt`; replaced in tests.
  final Future<void> Function(int attempt, Duration wait) delay;

  static Future<void> _defaultDelay(int attempt, Duration wait) =>
      Future.delayed(wait);

  /// The wait before the next attempt: [retryDelay], or the server's
  /// [retryAfter] when that is longer. Null when [retryAfter] exceeds
  /// [maxRetryAfter]: the retry is left to the next queue drain.
  Duration? waitFor(Duration? retryAfter) {
    if (retryAfter == null) return retryDelay;
    if (retryAfter > maxRetryAfter) return null;
    return retryAfter > retryDelay ? retryAfter : retryDelay;
  }
}

/// Classifies upload failures for retry decisions.
abstract final class ActivityUploadFailures {
  /// [AppException.details] of an upload refused at the server's cap on open
  /// uploads; such a record stays eligible for the next automatic retry.
  static const String uploadLimitDetails = 'upload_limit';

  /// Whether [error] means the stored session can no longer authorize an
  /// upload. Every further upload fails the same way until the user signs in
  /// again, so the queue stops draining at the first one.
  static bool isAuthFailure(Object error) =>
      error is AppException &&
      (error.code == AppErrorCode.sessionExpired ||
          error.code == AppErrorCode.notAuthenticated);

  /// Returns true if [error] represents a failure worth retrying (5xx, 408 or
  /// 429 response, network-level I/O error, or secure storage temporarily
  /// unreadable). Auth failures, missing GPX, and
  /// configuration errors are not transient.
  ///
  /// An unexpected non-[AppException] (e.g. a `TypeError`/`StateError` from a
  /// programming bug) is only retried when it is a known I/O/network failure;
  /// genuine bugs fail fast instead of burning the retry budget and masking
  /// the defect.
  static bool isTransient(Object error) {
    if (error is! AppException) {
      return isTransientIoError(error);
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
      return isTransientIoError(cause);
    }
    // HTTP 5xx, 408 (request timeout) and 429 (rate limited): transient.
    // Any other HTTP 4xx: permanent.
    final details = error.details;
    if (details != null &&
        (details.startsWith('HTTP 5') ||
            details == 'HTTP 408' ||
            details == 'HTTP 429')) {
      return true;
    }
    return false;
  }

  /// Whether [error] is the server's cap on open uploads: retried at the next
  /// drain, not at once.
  static bool isUploadLimit(Object error) =>
      error is AppException &&
      error.code == AppErrorCode.activityUploadFailed &&
      error.details == uploadLimitDetails;

  /// Whether [error] is a known transient I/O/network failure.
  static bool isTransientIoError(Object error) {
    return error is SocketException ||
        error is http.ClientException ||
        error is TimeoutException ||
        error is HttpException;
  }
}

/// Persisted backoff between the durable queue's own retries of one record.
///
/// Unlike [ActivityUploadRetryPolicy] (a few quick in-process attempts), this
/// spaces out the attempts across queue drains, so a record that keeps failing
/// does not hit the server on every app resume or connectivity change. The
/// wait doubles from [initialDelay] up to [maxDelay], with up to [jitter] of
/// it added so many devices do not retry in step.
class ActivityUploadBackoff {
  const ActivityUploadBackoff({
    this.initialDelay = const Duration(minutes: 1),
    this.maxDelay = const Duration(hours: 6),
    this.jitter = 0.2,
    double Function()? random,
  }) : _random = random;

  final Duration initialDelay;
  final Duration maxDelay;

  /// Fraction of the delay added at random, in `[0, 1]`.
  final double jitter;

  final double Function()? _random;

  static final math.Random _defaultRandom = math.Random();

  /// The wait after the [failureCount]-th consecutive failure (1-based).
  Duration delayAfter(int failureCount) {
    final exponent = (failureCount - 1).clamp(0, 30);
    final base = initialDelay.inMilliseconds * (1 << exponent);
    final capped = math.min(base, maxDelay.inMilliseconds);
    final fraction = (_random ?? _defaultRandom.nextDouble)();
    final withJitter = capped * (1 + jitter * fraction);
    return Duration(
      milliseconds: math.min(withJitter.round(), maxDelay.inMilliseconds),
    );
  }
}
