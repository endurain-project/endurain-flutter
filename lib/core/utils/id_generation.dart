library;

import 'dart:math';

/// Returns a timestamped unique suffix of the form
/// `<microseconds-since-epoch>_<8-char-hex-random>`.
///
/// The timestamp component orders suffixes chronologically; the random
/// component guards against collisions when multiple recordings start
/// within the same microsecond.
String uniqueSuffix() {
  final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
  final random = Random().nextInt(1 << 32).toRadixString(16);
  return '${timestamp}_$random';
}

/// Returns a local activity record ID of the form `activity_<suffix>`.
///
/// The prefix makes the ID self-describing in logs and stored JSON.
String localActivityId() => 'activity_${uniqueSuffix()}';
