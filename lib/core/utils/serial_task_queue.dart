import 'dart:async';

/// Runs asynchronous operations strictly one at a time, in submission order.
///
/// Each call to [run] enqueues its action behind every operation submitted
/// earlier; the returned future completes with that action's result (or error)
/// only after all prior operations have settled. A failing operation does not
/// break the queue — subsequent operations still run.
///
/// This serializes access to a non-reentrant resource (a single on-disk file, a
/// canonical stored record, a stateful import pipeline) without pulling in a
/// mutex package.
///
/// **Reentrancy:** never call [run] from inside an action already running on
/// the same queue — the inner call enqueues behind the still-running outer one
/// and would deadlock. Factor such code into an "unlocked" helper the action
/// invokes directly.
class SerialTaskQueue {
  Future<void> _tail = Future<void>.value();

  /// Enqueues [action] and returns a future for its eventual result.
  Future<T> run<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
