import 'dart:async';

import 'package:endurain/features/activity/services/start_countdown.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final origin = DateTime.utc(2026, 11, 25, 8);

  StartCountdown build(
    FakeAsync async, {
    int seconds = 5,
    List<int>? cues,
    DateTime Function()? now,
  }) {
    return StartCountdown(
      seconds: seconds,
      onCue: cues?.add,
      now: now ?? () => origin.add(async.elapsed),
    );
  }

  test('counts down and finishes with start', () {
    fakeAsync((async) {
      final cues = <int>[];
      final countdown = build(async, cues: cues);
      StartCountdownOutcome? outcome;
      unawaited(countdown.outcome.then((value) => outcome = value));

      countdown.start();
      expect(countdown.remainingSeconds, 5);

      async.elapse(const Duration(milliseconds: 2100));
      expect(countdown.remainingSeconds, 3);
      expect(outcome, isNull);

      async.elapse(const Duration(seconds: 3));
      expect(countdown.remainingSeconds, 0);
      expect(outcome, StartCountdownOutcome.start);
      expect(cues, [3, 2, 1]);
      countdown.dispose();
    });
  });

  test('adding time pushes the end back and cues again', () {
    fakeAsync((async) {
      final cues = <int>[];
      final countdown = build(async, seconds: 3, cues: cues);
      StartCountdownOutcome? outcome;
      unawaited(countdown.outcome.then((value) => outcome = value));
      countdown.start();

      async.elapse(const Duration(milliseconds: 1500));
      countdown.addSeconds(10);
      expect(countdown.remainingSeconds, 12);

      async.elapse(const Duration(seconds: 11));
      expect(outcome, isNull);

      async.elapse(const Duration(seconds: 2));
      expect(outcome, StartCountdownOutcome.start);
      expect(cues, [3, 2, 3, 2, 1]);
      countdown.dispose();
    });
  });

  test('skip starts right away and cancel does not start', () {
    fakeAsync((async) {
      final skipped = build(async);
      StartCountdownOutcome? skippedOutcome;
      unawaited(skipped.outcome.then((value) => skippedOutcome = value));
      skipped.start();
      skipped.skip();
      async.flushMicrotasks();
      expect(skippedOutcome, StartCountdownOutcome.start);
      skipped.dispose();

      final cancelled = build(async);
      StartCountdownOutcome? cancelledOutcome;
      unawaited(cancelled.outcome.then((value) => cancelledOutcome = value));
      cancelled.start();
      cancelled.cancel();
      // Later ticks do nothing once it has ended.
      async.elapse(const Duration(seconds: 10));
      expect(cancelledOutcome, StartCountdownOutcome.cancel);
      cancelled.dispose();
    });
  });

  test('catches up after a stall instead of running late', () {
    fakeAsync((async) {
      // The wall clock jumps ahead while the app was suspended, but timers
      // only fire once.
      var wallClock = origin;
      final cues = <int>[];
      final countdown = build(async, cues: cues, now: () => wallClock);
      StartCountdownOutcome? outcome;
      unawaited(countdown.outcome.then((value) => outcome = value));
      countdown.start();

      wallClock = origin.add(const Duration(seconds: 30));
      async.elapse(const Duration(milliseconds: 200));

      expect(outcome, StartCountdownOutcome.start);
      expect(cues, isEmpty);
      countdown.dispose();
    });
  });

  test('disposing an unfinished countdown cancels it', () {
    fakeAsync((async) {
      final countdown = build(async);
      StartCountdownOutcome? outcome;
      unawaited(countdown.outcome.then((value) => outcome = value));
      countdown.start();

      countdown.dispose();
      async.flushMicrotasks();

      expect(outcome, StartCountdownOutcome.cancel);
    });
  });
}
