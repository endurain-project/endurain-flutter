import 'package:endurain/core/models/app_exception.dart';

/// Runs [action], always invoking [onCleanup] when it fails.
///
/// Re-throws [AppException]s unchanged; wraps any other error in an
/// [AppException] with [fallbackCode]. Used by the PKCE auth flows to clear
/// transient verifier state on any failure while normalizing unexpected
/// errors to a typed [AppException].
Future<T> runWithCleanup<T>(
  Future<T> Function() action, {
  required void Function() onCleanup,
  required AppErrorCode fallbackCode,
}) async {
  try {
    return await action();
  } on AppException {
    onCleanup();
    rethrow;
  } catch (e) {
    onCleanup();
    throw AppException(fallbackCode, cause: e);
  }
}
