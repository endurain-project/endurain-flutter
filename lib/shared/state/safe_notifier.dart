import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] that is safe to notify from an async continuation.
///
/// Controllers routinely do `await something(); notifyListeners();`. If the
/// owning route is popped while that await is in flight the controller is
/// already disposed when the continuation resumes, and `notifyListeners()`
/// throws `A <Controller> was used after being disposed`. In release builds the
/// assertion is compiled out, so the bug surfaces only in debug or as a crash
/// report from the field.
///
/// Guarding every call site by hand meant the same three-line helper was copied
/// into five controllers under two different names, and six others simply
/// omitted it. Extending this base makes the safe behaviour the default:
/// subclasses call [notify] instead of `notifyListeners`, and [isDisposed] is
/// available for any additional post-await bail-out.
///
/// Subclasses that override [dispose] must still call `super.dispose()`.
abstract class SafeNotifier extends ChangeNotifier {
  bool _isDisposed = false;

  /// Whether [dispose] has run. Useful for skipping work in a continuation
  /// that resumed after the owner went away.
  bool get isDisposed => _isDisposed;

  /// Notifies listeners unless this notifier has been disposed.
  ///
  /// Use this in place of `notifyListeners()` throughout subclasses.
  @protected
  void notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
