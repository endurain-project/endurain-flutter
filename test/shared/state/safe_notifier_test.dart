import 'package:endurain/shared/state/safe_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafeNotifier', () {
    test('notifies listeners while alive', () {
      final notifier = _TestNotifier();
      var calls = 0;
      notifier.addListener(() => calls++);

      notifier.bump();
      notifier.bump();

      expect(calls, 2);
      expect(notifier.isDisposed, isFalse);
    });

    test('does not notify after dispose', () {
      final notifier = _TestNotifier();
      var calls = 0;
      notifier.addListener(() => calls++);
      notifier.dispose();

      // Would throw "A _TestNotifier was used after being disposed" if it
      // reached ChangeNotifier.notifyListeners.
      notifier.bump();

      expect(calls, 0);
      expect(notifier.isDisposed, isTrue);
    });

    test('notify after dispose does not throw', () {
      final notifier = _TestNotifier();
      notifier.dispose();

      expect(notifier.bump, returnsNormally);
    });

    test('an await that resumes after dispose is safe', () async {
      // The real-world shape this class exists for: a controller awaits work,
      // the route is popped mid-flight, and the continuation then notifies.
      final notifier = _TestNotifier();
      var calls = 0;
      notifier.addListener(() => calls++);

      final pending = notifier.bumpAfterDelay();
      notifier.dispose();
      await pending;

      expect(calls, 0);
    });

    test('isDisposed lets a subclass bail out of post-await work', () async {
      final notifier = _TestNotifier();

      final pending = notifier.recordUnlessDisposed();
      notifier.dispose();
      await pending;

      expect(notifier.didWorkAfterAwait, isFalse);
    });
  });
}

class _TestNotifier extends SafeNotifier {
  bool didWorkAfterAwait = false;

  void bump() => notify();

  Future<void> bumpAfterDelay() async {
    await Future<void>.delayed(Duration.zero);
    notify();
  }

  Future<void> recordUnlessDisposed() async {
    await Future<void>.delayed(Duration.zero);
    if (isDisposed) {
      return;
    }
    didWorkAfterAwait = true;
  }
}
