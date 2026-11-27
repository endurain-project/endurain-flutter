import 'dart:async';

import 'package:endurain/core/utils/single_flight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SingleFlight', () {
    test('runs one pass when idle', () async {
      var passes = 0;
      final flight = SingleFlight<int>(pass: () async => ++passes);

      expect(await flight.run(), 1);
      expect(flight.isRunning, isFalse);
      expect(await flight.run(), 2);
    });

    test('concurrent calls join and trigger a single follow-up pass', () async {
      var passes = 0;
      var gate = Completer<void>();
      final flight = SingleFlight<int>(
        pass: () async {
          passes++;
          await gate.future;
          return 1;
        },
        combine: (a, b) => a + b,
      );

      final first = flight.run();
      final second = flight.run();
      final third = flight.run();
      expect(identical(first, second), isTrue);
      expect(identical(first, third), isTrue);
      expect(flight.isRunning, isTrue);

      final firstGate = gate;
      gate = Completer<void>();
      firstGate.complete();
      await Future<void>.delayed(Duration.zero);
      gate.complete();

      expect(await first, 2);
      expect(passes, 2);
      expect(flight.isRunning, isFalse);
    });

    test('keeps the last result without a combine function', () async {
      var passes = 0;
      final gate = Completer<void>();
      final flight = SingleFlight<int>(
        pass: () async {
          final n = ++passes;
          if (n == 1) await gate.future;
          return n;
        },
      );

      final result = flight.run();
      unawaited(flight.run());
      gate.complete();

      expect(await result, 2);
    });

    test('canContinue stops the follow-up pass', () async {
      var passes = 0;
      var allowed = true;
      final gate = Completer<void>();
      final flight = SingleFlight<void>(
        pass: () async {
          passes++;
          await gate.future;
        },
        canContinue: () => allowed,
      );

      final run = flight.run();
      unawaited(flight.run());
      allowed = false;
      gate.complete();
      await run;

      expect(passes, 1);
    });

    test('onSettled fires once per flight after it clears', () async {
      var settled = 0;
      late SingleFlight<void> flight;
      final seenRunning = <bool>[];
      flight = SingleFlight<void>(
        pass: () async {},
        onSettled: () {
          settled++;
          seenRunning.add(flight.isRunning);
        },
      );

      final run = flight.run();
      unawaited(flight.run());
      await run;
      await flight.run();

      expect(settled, 2);
      expect(seenRunning, [false, false]);
    });

    test('a failing pass fails the run and the flight can run again', () async {
      var fail = true;
      final flight = SingleFlight<int>(
        pass: () async {
          if (fail) throw StateError('boom');
          return 7;
        },
      );

      await expectLater(flight.run(), throwsStateError);
      expect(flight.isRunning, isFalse);
      fail = false;
      expect(await flight.run(), 7);
    });
  });
}
