import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs an asynchronous pass single-flight, with a follow-up pass for callers
/// that arrive while one is running.
///
/// `run` starts a pass when idle. A call made while a pass is running joins it
/// (it receives the same future) and schedules exactly one more pass once the
/// current one finishes, so work that became pending mid-pass is never missed
/// and a burst of triggers collapses into at most one extra pass.
///
/// The returned future completes after the last pass with the passes' results
/// folded through `combine` (the last pass's result when `combine` is omitted).
/// A pass that throws fails the whole run; make the pass catch its own errors
/// when a failure should not cancel the follow-up.
class SingleFlight<T> {
  SingleFlight({
    required Future<T> Function() pass,
    T Function(T previous, T next)? combine,
    bool Function()? canContinue,
    void Function()? onSettled,
  }) : _pass = pass,
       _combine = combine,
       _canContinue = canContinue,
       _onSettled = onSettled;

  final Future<T> Function() _pass;
  final T Function(T previous, T next)? _combine;
  final bool Function()? _canContinue;
  final void Function()? _onSettled;

  Future<T>? _inFlight;
  bool _followUpRequested = false;

  /// Whether a pass is currently running.
  @visibleForTesting
  bool get isRunning => _inFlight != null;

  /// Starts a pass, or joins the running one and requests a follow-up pass.
  Future<T> run() {
    final inFlight = _inFlight;
    if (inFlight != null) {
      _followUpRequested = true;
      return inFlight;
    }
    return _inFlight = _runUntilSettled().whenComplete(() {
      _inFlight = null;
      _onSettled?.call();
    });
  }

  Future<T> _runUntilSettled() async {
    final combine = _combine;
    late T total;
    var first = true;
    do {
      _followUpRequested = false;
      final result = await _pass();
      total = first || combine == null ? result : combine(total, result);
      first = false;
    } while (_followUpRequested && (_canContinue?.call() ?? true));
    return total;
  }
}
