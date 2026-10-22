import 'dart:async';

/// Tracks the active (non-paused) duration of a recording and drives the
/// once-per-second UI tick.
///
/// Elapsed time is the sum of completed segments plus the running segment, so
/// pausing freezes it and resuming starts a new running segment without losing
/// the total.
class RecordingElapsedClock {
  RecordingElapsedClock(this._now);

  final DateTime Function() _now;
  Timer? _ticker;
  DateTime? _segmentStartedAt;
  int _elapsedBeforeSegmentSeconds = 0;

  /// Seconds recorded so far, including the running segment.
  int get currentSeconds {
    final segmentStartedAt = _segmentStartedAt;
    if (segmentStartedAt == null) {
      return _elapsedBeforeSegmentSeconds;
    }
    final segmentSeconds = _now().difference(segmentStartedAt).inSeconds;
    return _elapsedBeforeSegmentSeconds +
        (segmentSeconds < 0 ? 0 : segmentSeconds);
  }

  /// Starts counting a running segment from [startedAt].
  void beginSegment(DateTime startedAt) {
    _segmentStartedAt = startedAt;
  }

  /// Stops counting and returns the frozen total.
  ///
  /// [elapsedSeconds] overrides the locally computed total, for callers that
  /// have an authoritative value (the native recorder's own clock).
  int freeze({int? elapsedSeconds}) {
    final total = elapsedSeconds ?? currentSeconds;
    _elapsedBeforeSegmentSeconds = total;
    _segmentStartedAt = null;
    cancelTicker();
    return total;
  }

  /// Clears all elapsed time and stops the ticker.
  void reset() {
    cancelTicker();
    _segmentStartedAt = null;
    _elapsedBeforeSegmentSeconds = 0;
  }

  /// Restores a recovered session's clock. A null [segmentStartedAt] leaves the
  /// clock frozen at [elapsedBeforeSeconds].
  void restore({
    required int elapsedBeforeSeconds,
    required DateTime? segmentStartedAt,
  }) {
    _elapsedBeforeSegmentSeconds = elapsedBeforeSeconds;
    _segmentStartedAt = segmentStartedAt;
  }

  /// Calls [onTick] every second, replacing any previous ticker.
  void startTicker(void Function() onTick) {
    cancelTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => onTick());
  }

  void cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}
