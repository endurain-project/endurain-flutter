import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/models/app_exception.dart';

void main() {
  group('AppException', () {
    test('renders the code name alone when no context is present', () {
      const exception = AppException(AppErrorCode.sessionExpired);

      expect(exception.code, AppErrorCode.sessionExpired);
      expect(exception.details, isNull);
      expect(exception.cause, isNull);
      expect(exception.toString(), 'sessionExpired');
    });

    test('appends server details to the description', () {
      const exception = AppException(
        AppErrorCode.loginFailed,
        details: 'Bad credentials',
      );

      expect(exception.toString(), 'loginFailed: Bad credentials');
    });

    test('appends the underlying cause to the description', () {
      final cause = StateError('boom');
      final exception = AppException(AppErrorCode.loginError, cause: cause);

      expect(exception.toString(), 'loginError: $cause');
    });

    test('includes both details and cause when present', () {
      const exception = AppException(
        AppErrorCode.tokenExchangeFailed,
        details: 'context',
        cause: FormatException('bad'),
      );

      expect(
        exception.toString(),
        'tokenExchangeFailed: context: ${const FormatException('bad')}',
      );
    });
  });
}
