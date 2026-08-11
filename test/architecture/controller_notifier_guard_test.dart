import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the controller notification contract.
///
/// Every feature controller must extend `SafeNotifier` rather than
/// `ChangeNotifier` directly, and must notify through its guarded `notify()`.
///
/// The failure this prevents is specific and was live in the codebase: a
/// controller that does `await something(); notifyListeners();` throws
/// `A SomeController was used after being disposed` when the owning route is
/// popped while the await is in flight. Five controllers had hand-rolled the
/// guard under two different names and six had simply omitted it, so the
/// convention could not be relied on. A grep-level guard is cheap and keeps a
/// new controller from silently reintroducing the bug.
void main() {
  final controllerFiles =
      Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.contains('/controllers/') &&
                file.path.endsWith('.dart'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('controller files exist to guard', () {
    expect(controllerFiles, isNotEmpty);
  });

  test('no feature controller extends ChangeNotifier directly', () {
    final offenders = <String>[];
    for (final file in controllerFiles) {
      if (file.readAsStringSync().contains('extends ChangeNotifier')) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Extend SafeNotifier (lib/shared/state/safe_notifier.dart) instead, '
          'so notifying after dispose is a no-op: ${offenders.join(', ')}',
    );
  });

  test('no feature controller calls notifyListeners directly', () {
    final offenders = <String>[];
    for (final file in controllerFiles) {
      if (file.readAsStringSync().contains('notifyListeners()')) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Call the guarded SafeNotifier.notify() instead of '
          'notifyListeners(): ${offenders.join(', ')}',
    );
  });

  test('no feature controller re-declares its own disposal flag', () {
    // SafeNotifier already exposes `isDisposed`; a local copy drifts out of
    // sync with the base class's dispose().
    final offenders = <String>[];
    for (final file in controllerFiles) {
      if (file.readAsStringSync().contains('bool _isDisposed')) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use SafeNotifier.isDisposed instead of a local flag: '
          '${offenders.join(', ')}',
    );
  });
}
