/// How far a route point may be from the nearest heart rate reading and still
/// take its value. Readings are usually 1-5 s apart, so this covers occasional
/// gaps of up to 20 s without stretching a reading across a real dropout.
const int _matchToleranceMs = 10000;

/// Looks up the heart rate at a time in readings sorted by start.
///
/// Readings can overlap, for example when two sources recorded heart rate at
/// once, so the reading just before a time is not always the one that covers
/// it. [_maxEndMs] holds the latest end among the readings up to each index;
/// it never decreases, so a binary search over it finds the earliest reading
/// that covers a time.
class HealthHeartRateIndex {
  HealthHeartRateIndex(this._samples)
    : _maxEndMs = List.filled(_samples.length, 0),
      _maxEndIndex = List.filled(_samples.length, 0) {
    for (var i = 0; i < _samples.length; i++) {
      if (i > 0 && _maxEndMs[i - 1] >= _samples[i].endMs) {
        _maxEndMs[i] = _maxEndMs[i - 1];
        _maxEndIndex[i] = _maxEndIndex[i - 1];
      } else {
        _maxEndMs[i] = _samples[i].endMs;
        _maxEndIndex[i] = i;
      }
    }
  }

  final List<HealthHeartRateSample> _samples;

  /// Latest `endMs` among `_samples[0..i]`.
  final List<int> _maxEndMs;

  /// Index of the earliest reading holding `_maxEndMs[i]`.
  final List<int> _maxEndIndex;

  /// Returns the heart rate at [targetMs], or `null` when no reading covers
  /// it or lies within [_matchToleranceMs] of it.
  ///
  /// A reading that covers [targetMs] wins, the earliest-starting one if
  /// several do. Otherwise the nearest reading wins: the one ending last
  /// before [targetMs] or the first one starting after it, the earlier one on
  /// a tie.
  int? bpmAt(int targetMs) {
    // Readings [0, startedCount) start at or before targetMs.
    final startedCount = _firstIndexWhere(
      (i) => _samples[i].startMs > targetMs,
    );
    if (startedCount > 0) {
      // Earliest reading whose running max end reaches targetMs. The max
      // first reaches it at that reading, so the reading itself covers it.
      final covering = _firstIndexWhere(
        (i) => _maxEndMs[i] >= targetMs,
        end: startedCount,
      );
      if (covering < startedCount) return _samples[covering].bpm;
    }

    int? hr;
    var closest = _matchToleranceMs + 1;
    if (startedCount > 0) {
      final before = _maxEndIndex[startedCount - 1];
      final distance = targetMs - _samples[before].endMs;
      if (distance < closest) {
        hr = _samples[before].bpm;
        closest = distance;
      }
    }
    if (startedCount < _samples.length) {
      final distance = _samples[startedCount].startMs - targetMs;
      if (distance < closest) hr = _samples[startedCount].bpm;
    }
    return hr;
  }

  /// First index in `[0, end)` for which the monotonic [test] holds, or [end].
  int _firstIndexWhere(bool Function(int index) test, {int? end}) {
    var low = 0;
    var high = end ?? _samples.length;
    while (low < high) {
      final middle = low + (high - low) ~/ 2;
      if (test(middle)) {
        high = middle;
      } else {
        low = middle + 1;
      }
    }
    return low;
  }
}

/// Lightweight heart-rate reading covering `startMs..endMs`. An instant
/// reading has `startMs == endMs`.
class HealthHeartRateSample {
  const HealthHeartRateSample._({
    required this.startMs,
    required this.endMs,
    required this.bpm,
  });

  factory HealthHeartRateSample.interval({
    required DateTime start,
    required DateTime end,
    required int bpm,
  }) {
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    return HealthHeartRateSample._(
      startMs: startMs,
      endMs: endMs < startMs ? startMs : endMs,
      bpm: bpm,
    );
  }

  final int startMs;
  final int endMs;
  final int bpm;

  static int byStart(HealthHeartRateSample a, HealthHeartRateSample b) =>
      a.startMs.compareTo(b.startMs);
}
