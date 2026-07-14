import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/auth/controllers/auth_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('AuthSessionController', () {
    test('initializes from stored auth state', () async {
      final storage = SecureStorageService();
      await AuthSessionStore(storage: storage).saveSession(
        origin: 'https://example.test',
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        sessionId: 'session-1',
        profileId: '42',
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
  _FakeAuthService({required this.authenticated})
    : super(
        storage: SecureStorageService(),
        sessionStore: AuthSessionStore(storage: SecureStorageService()),
      );

  final bool authenticated;

  @override
  Future<bool> isAuthenticated() async => authenticated;
}
