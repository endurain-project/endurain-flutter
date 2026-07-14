import 'dart:async';

import 'package:endurain/core/utils/serial_task_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SerialTaskQueue', () {
    test('runs operations one at a time in submission order', () async {
      final queue = SerialTaskQueue();
      final log = <String>[];
      final gate = Completer<void>();

      final first = queue.run(() async {
        log.add('first-start');
        await gate.future;
        log.add('first-end');
        return 1;
      });
      final second = queue.run(() async {
        log.add('second-start');
        return 2;
      });

      // Let pending microtasks run: the second operation must not start until
      // the first has finished, so only the first has begun at this point.
      await Future<void>.delayed(Duration.zero);
      expect(log, ['first-start']);

      gate.complete();
      expect(await first, 1);
      expect(await second, 2);
      expect(log, ['first-start', 'first-end', 'second-start']);
    });

    test('propagates the error to the caller and keeps draining', () async {
      final queue = SerialTaskQueue();

      final failing = queue.run<int>(() async {
        throw StateError('boom');
      });
      await expectLater(failing, throwsA(isA<StateError>()));

      // A failed operation must not wedge the queue.
      expect(await queue.run(() async => 'ok'), 'ok');
    });

    test('returns the typed result of each operation', () async {
      final queue = SerialTaskQueue();
      expect(await queue.run<int>(() async => 42), 42);
      expect(await queue.run<String>(() async => 'x'), 'x');
    });
  });
}
