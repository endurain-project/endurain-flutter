import 'dart:async';

import 'package:endurain/shared/state/safe_notifier.dart';

/// How a [StartCountdown] ended.
enum StartCountdownOutcome {
  /// The countdown reached zero or the user chose to start right away.
  start,

  /// The user backed out; recording must not start.
  cancel,
}

/// Counts down to the moment a recording should start.
///
/// The countdown is anchored to an end time rather than counting ticks, so a
/// stalled timer (the app briefly suspended, a slow frame) catches up instead
/// of drifting late. [onCue] fires once for each of the last [cueSeconds]
/// whole seconds so the caller can speak them.
class StartCountdown extends SafeNotifier {
  StartCountdown({
    required int seconds,
    this.cueSeconds = defaultCueSeconds,
    this.onCue,
    DateTime Function()? now,
    Duration tickInterval = const Duration(milliseconds: 200),
  }) : assert(seconds > 0),
       _now = now ?? DateTime.now,
       _tickInterval = tickInterval,
       _initialSeconds = seconds;

  static const int defaultCueSeconds = 3;

  /// Upper bound for the remaining time, however often time is added.
  static const Duration maxRemaining = Duration(minutes: 10);

  /// Number of final seconds announced through [onCue].
  final int cueSeconds;

  /// Called with the whole seconds left (`cueSeconds`..1) as each is reached.
  final void Function(int secondsLeft)? onCue;

  final DateTime Function() _now;
  final Duration _tickInterval;
  final int _initialSeconds;
  final Completer<StartCountdownOutcome> _outcome = Completer();

  Timer? _ticker;
  DateTime? _endsAt;
  int _remainingSeconds = 0;
  int? _lastCuedSecond;

  /// Whole seconds left, rounded up (shows "1" until the very end).
  int get remainingSeconds => _remainingSeconds;

  /// Completes once with how the countdown ended.
  Future<StartCountdownOutcome> get outcome => _outcome.future;

  bool get isFinished => _outcome.isCompleted;

  /// Starts counting. Calling it again has no effect.
  void start() {
    if (_endsAt != null || isFinished) {
      return;
    }
    _endsAt = _now().add(Duration(seconds: _initialSeconds));
    _ticker = Timer.periodic(_tickInterval, (_) => _tick());
    _tick();
  }

  /// Pushes the end time back by [seconds].
  void addSeconds(int seconds) {
    final endsAt = _endsAt;
    if (endsAt == null || isFinished || seconds <= 0) {
      return;
    }
    final now = _now();
    var extended = endsAt.add(Duration(seconds: seconds));
    final latest = now.add(maxRemaining);
    if (extended.isAfter(latest)) {
      extended = latest;
    }
    _endsAt = extended;
    _tick();
  }

  /// Ends the countdown now and starts recording.
  void skip() => _finish(StartCountdownOutcome.start);

  /// Ends the countdown without recording.
  void cancel() => _finish(StartCountdownOutcome.cancel);

  void _tick() {
    final endsAt = _endsAt;
    if (endsAt == null || isFinished) {
      return;
    }
    final left = endsAt.difference(_now());
    if (left <= Duration.zero) {
      _setRemaining(0);
      _finish(StartCountdownOutcome.start);
      return;
    }
    final seconds = (left.inMilliseconds / 1000).ceil();
    _setRemaining(seconds);
    if (seconds <= cueSeconds) {
      // Each second is cued at most once, even when ticks are missed; after
      // time is added the cues run again from the new value.
      if (_lastCuedSecond == null || seconds < _lastCuedSecond!) {
        _lastCuedSecond = seconds;
        onCue?.call(seconds);
      }
    } else {
      _lastCuedSecond = null;
    }
  }

  void _setRemaining(int seconds) {
    if (_remainingSeconds == seconds) {
      return;
    }
    _remainingSeconds = seconds;
    notify();
  }

  void _finish(StartCountdownOutcome outcome) {
    if (isFinished) {
      return;
    }
    _ticker?.cancel();
    _ticker = null;
    _outcome.complete(outcome);
    notify();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    if (!isFinished) {
      _outcome.complete(StartCountdownOutcome.cancel);
    }
    super.dispose();
  }
}
