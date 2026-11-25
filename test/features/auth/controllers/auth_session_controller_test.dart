import 'dart:async';

import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/auth/auth_session_store.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/auth/controllers/auth_session_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../helpers/recording_diagnostics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('AuthSessionController', () {
    test('records each mode change with its reason', () async {
      final diagnostics = RecordingDiagnostics();
      final service = _FakeAuthService(authenticated: true);
      final controller = AuthSessionController(
        authService: service,
        diagnostics: diagnostics,
      );

      await controller.initialize();
      await Future<void>.delayed(Duration.zero);
      controller.continueAsGuest();
      controller.markAuthenticated();

      expect(diagnostics.events, [
        DiagnosticsEvents.sessionModeChanged,
        DiagnosticsEvents.sessionModeChanged,
        DiagnosticsEvents.sessionModeChanged,
      ]);
      expect(diagnostics.details, [
        {
          'from': 'loading',
          'to': 'authenticated',
          'reason': 'launch_stored_session',
        },
        {'from': 'authenticated', 'to': 'guest', 'reason': 'signed_out'},
        {'from': 'guest', 'to': 'authenticated', 'reason': 'signed_in'},
      ]);
      controller.dispose();
    });

    test('records an unreadable launch and an expired session', () async {
      final diagnostics = RecordingDiagnostics();
      final controller = AuthSessionController(
        authService: _FakeAuthService(throws: true),
        diagnostics: diagnostics,
      );
      await controller.initialize();

      expect(diagnostics.details.single, {
        'from': 'loading',
        'to': 'guest',
        'reason': 'launch_session_unreadable',
        'type': 'AppException',
        'code': 'secureStorageReadFailed',
      });

      final expiring = RecordingDiagnostics();
      final expired = AuthSessionController(
        authService: _FakeAuthService(
          authenticated: true,
          rejectOnConfirm: true,
        ),
        diagnostics: expiring,
      );
      await expired.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(expiring.details.last, {
        'from': 'authenticated',
        'to': 'guest',
        'reason': 'session_ended',
      });
      controller.dispose();
      expired.dispose();
    });

    test('records a revalidation that could not run', () async {
      final diagnostics = RecordingDiagnostics();
      final service = _FakeAuthService(authenticated: true);
      final controller = AuthSessionController(
        authService: service,
        diagnostics: diagnostics,
      );
      await controller.initialize();
      await Future<void>.delayed(Duration.zero);

      service.throws = true;
      await controller.revalidate();

      expect(controller.isAuthenticated, isTrue);
      expect(diagnostics.single(DiagnosticsEvents.sessionRevalidateFailed), {
        'type': 'AppException',
        'code': 'secureStorageReadFailed',
      });
      controller.dispose();
    });

    test(
      'starts in guest mode when the stored session is unreadable',
      () async {
        final controller = AuthSessionController(
          authService: _FakeAuthService(throws: true),
        );

        await controller.initialize();

        expect(controller.isGuest, isTrue);
        expect(controller.isLoading, isFalse);
        controller.dispose();
      },
    );

    test(
      'resume promotes to authenticated once the session is readable',
      () async {
        final service = _FakeAuthService(throws: true);
        final controller = AuthSessionController(authService: service);
        await controller.initialize();
        expect(controller.isGuest, isTrue);

        service.throws = false;
        service.authenticated = true;
        await controller.revalidate();

        expect(controller.isAuthenticated, isTrue);
        controller.dispose();
      },
    );

    test('resume leaves a genuine guest untouched', () async {
      final service = _FakeAuthService(authenticated: false);
      final controller = AuthSessionController(authService: service);
      await controller.initialize();

      service.authenticated = true;
      await controller.revalidate();

      expect(controller.isGuest, isTrue);
      controller.dispose();
    });

    test('initializes from stored auth state', () async {
      final storage = SecureStorageService();
      await AuthSessionStore(storage: storage).saveSession(
        origin: 'https://example.test',
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        sessionId: 'session-1',
        accountId: '42',
        expiresInSeconds: 3600,
      );
      final controller = AuthSessionController(
        authService: AuthService(storage: storage),
      );

      await controller.initialize();

      expect(controller.isLoading, isFalse);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.mode, SessionMode.authenticated);
      controller.dispose();
    });

    test(
      'launch does not wait for the server to confirm the session',
      () async {
        final service = _FakeAuthService(authenticated: true, hang: true);
        final controller = AuthSessionController(authService: service);

        await controller.initialize();

        expect(controller.isAuthenticated, isTrue);
        controller.dispose();
      },
    );

    test(
      'launch revalidation drops to guest when the server rejects',
      () async {
        final service = _FakeAuthService(
          authenticated: true,
          rejectOnConfirm: true,
        );
        final controller = AuthSessionController(authService: service);

        await controller.initialize();
        expect(controller.isAuthenticated, isTrue);
        await Future<void>.delayed(Duration.zero);

        expect(controller.isGuest, isTrue);
        controller.dispose();
      },
    );

    test('initializes into guest mode when there is no session', () async {
      final controller = AuthSessionController(
        authService: _FakeAuthService(authenticated: false),
      );

      await controller.initialize();

      // Local-first: the app starts on the map without a login gate.
      expect(controller.mode, SessionMode.guest);
      expect(controller.isGuest, isTrue);
      expect(controller.isAuthenticated, isFalse);
      controller.dispose();
    });

    test('continueAsGuest enters guest mode', () {
      final controller = AuthSessionController(
        authService: _FakeAuthService(authenticated: false),
      );

      controller.continueAsGuest();

      expect(controller.isGuest, isTrue);
      controller.dispose();
    });

    test('marks authenticated then drops back to guest', () {
      final controller = AuthSessionController(
        authService: AuthService(storage: SecureStorageService()),
      );

      controller.markAuthenticated();
      expect(controller.isAuthenticated, isTrue);
      expect(controller.isLoading, isFalse);

      controller.continueAsGuest();
      expect(controller.mode, SessionMode.guest);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.isLoading, isFalse);
      controller.dispose();
    });

    test('drops to guest when the auth layer ends the session', () async {
      final storage = SecureStorageService();
      await AuthSessionStore(storage: storage).saveSession(
        origin: 'https://example.test',
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        sessionId: 'session-1',
        accountId: '42',
        expiresInSeconds: 3600,
      );
      final diagnostics = RecordingDiagnostics();
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          return http.Response('{"detail":"Session ended"}', 401);
        }),
      );
      final controller = AuthSessionController(
        authService: service,
        diagnostics: diagnostics,
      );
      controller.markAuthenticated();

      // A refresh triggered by an API call's 401, not by the controller.
      expect(await service.refreshToken(), isFalse);

      expect(controller.isGuest, isTrue);
      expect(diagnostics.details.last, {
        'from': 'authenticated',
        'to': 'guest',
        'reason': 'session_cleared',
      });
      controller.dispose();
    });

    test('stops listening for ended sessions once disposed', () async {
      final service = AuthService(
        storage: SecureStorageService(),
        httpClient: MockClient((request) async => fail('No request')),
      );
      final controller = AuthSessionController(authService: service);
      controller.markAuthenticated();
      controller.dispose();

      // No session stored: the refresh reports it ended.
      expect(await service.refreshToken(), isFalse);

      expect(controller.isAuthenticated, isTrue);
    });

    group('revalidate', () {
      test('does nothing in guest mode', () async {
        final controller = AuthSessionController(
          authService: _FakeAuthService(authenticated: false),
        );
        controller.continueAsGuest();
        var notified = false;
        controller.addListener(() => notified = true);

        await controller.revalidate();

        expect(notified, isFalse);
        expect(controller.isGuest, isTrue);
        controller.dispose();
      });

      test('keeps authenticated state when session is still valid', () async {
        final controller = AuthSessionController(
          authService: _FakeAuthService(authenticated: true),
        );
        controller.markAuthenticated();
        var notified = false;
        controller.addListener(() => notified = true);

        await controller.revalidate();

        // State unchanged → no notification expected.
        expect(notified, isFalse);
        expect(controller.isAuthenticated, isTrue);
        controller.dispose();
      });

      test('keeps the current mode when the session cannot be read', () async {
        final controller = AuthSessionController(
          authService: _FakeAuthService(throws: true),
        );
        controller.markAuthenticated();

        await controller.revalidate();

        expect(controller.isAuthenticated, isTrue);
        controller.dispose();
      });

      test('ignores a check that a new sign-in overtook', () async {
        final service = _FakeAuthService(authenticated: true)
          ..confirmation = Completer<bool>();
        final controller = AuthSessionController(authService: service);
        controller.markAuthenticated();

        final revalidation = controller.revalidate();
        // The user signs in again while the old session is being checked.
        controller.continueAsGuest();
        controller.markAuthenticated();
        service.confirmation!.complete(false);
        await revalidation;

        expect(controller.isAuthenticated, isTrue);
        controller.dispose();
      });

      test('drops to guest when the session expires on resume', () async {
        final controller = AuthSessionController(
          authService: _FakeAuthService(authenticated: false),
        );
        controller.markAuthenticated();
        var notified = false;
        controller.addListener(() => notified = true);

        await controller.revalidate();

        expect(notified, isTrue);
        expect(controller.isGuest, isTrue);
        expect(controller.isAuthenticated, isFalse);
        controller.dispose();
      });
    });
  });
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({
    this.authenticated = false,
    this.throws = false,
    this.hang = false,
    this.rejectOnConfirm = false,
  }) : super(
         storage: SecureStorageService(),
         sessionStore: AuthSessionStore(storage: SecureStorageService()),
       );

  bool authenticated;
  bool throws;

  /// [isAuthenticated] (the server confirmation) never completes.
  final bool hang;

  /// The server confirmation reports the session as rejected.
  final bool rejectOnConfirm;

  @override
  Future<bool> hasStoredSession() async {
    if (throws) {
      throw const AppException(AppErrorCode.secureStorageReadFailed);
    }
    return authenticated;
  }

  /// When set, [isAuthenticated] answers with this completer's value.
  Completer<bool>? confirmation;

  @override
  Future<bool> isAuthenticated() async {
    if (confirmation != null) {
      return confirmation!.future;
    }
    if (hang) {
      return Completer<bool>().future;
    }
    if (rejectOnConfirm) {
      return false;
    }
    if (throws) {
      throw const AppException(AppErrorCode.secureStorageReadFailed);
    }
    return authenticated;
  }
}
