import 'dart:math';

/// Cryptographically secure RNG shared by every identifier helper below.
///
/// A secure source makes generated identifiers unpredictable as well as
/// unique, so the same helper is safe for session revisions and upload
/// idempotency keys — not just collision avoidance.
final Random _secureRandom = Random.secure();

/// Returns a timestamped unique suffix of the form
/// `<microseconds-since-epoch>_<8-char-hex-random>`.
///
/// The timestamp component orders suffixes chronologically; the random
/// component guards against collisions when multiple identifiers are created
/// within the same microsecond.
String uniqueSuffix() {
  final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
  final random = _secureRandom.nextInt(1 << 32).toRadixString(16);
  return '${timestamp}_$random';
}

/// Returns a local activity record ID of the form `activity_<suffix>`.
///
/// The prefix makes the ID self-describing in logs and stored JSON.
String localActivityId() => 'activity_${uniqueSuffix()}';

/// Returns a recording-session ID of the form `session_<suffix>`.
///
/// Used as the fallback local session id when a recording is started without
/// an explicit id. Production always supplies the local activity id, so this
/// is only reached by direct service usage (e.g. tests).
String recordingSessionId() => 'session_${uniqueSuffix()}';

/// Returns an opaque revision token for a stored auth/connection session.
///
/// The auth session store tags each stored revision with one of these so
/// optimistic replacement and single-flight refresh can detect concurrent
/// changes. The value is compared only for equality; its shape is not parsed.
String connectionRevision() => uniqueSuffix();
