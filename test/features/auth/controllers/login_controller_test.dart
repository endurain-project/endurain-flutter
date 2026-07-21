import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/identity_provider.dart' as core;
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/services/server_settings_service.dart';
import 'package:endurain/core/services/sso_service.dart';
import 'package:endurain/features/auth/services/auth_coordinator.dart';
import 'package:endurain/features/auth/controllers/login_controller.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';

import '../../../helpers/fake_app_links_service.dart';
import '../../../helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('LoginController', () {
    test('loads server settings and SSO providers', () async {
      final storage = SecureStorageService();
      final controller = LoginController(
        authCoordinator: _repository(
          storage: storage,
          client: MockClient((request) async {
            if (request.url.path ==
                ApiEndpoints.defaults.serverSettingsEndpoint) {
              return http.Response(
                '{"sso_enabled":true,"local_login_enabled":true}',
                200,
              );
            }
            if (request.url.path == ApiEndpoints.defaults.idpListEndpoint) {
              return http.Response(
                '[{"id":1,"slug":"keycloak","name":"Keycloak","icon":"keycloak"}]',
                200,
              );
            }
            fail('Unexpected request to ${request.url}');
          }),
        ),
        appLinksService: const EmptyAppLinksService(),
      );

      final autoRedirectProvider = await controller.submitServerUrl(
        'https://example.test',
      );

      expect(autoRedirectProvider, isNull);
      expect(controller.isStep2, isTrue);
      expect(controller.availableIdPs.single.slug, 'keycloak');
      expect(controller.localLoginEnabled, isTrue);
      controller.dispose();
    });

    test('shows MFA input when local login requires MFA', () async {
      final storage = SecureStorageService();
      final controller = LoginController(
        authCoordinator: _repository(
          storage: storage,
          client: MockClient((request) async {
            expect(request.url.path, ApiEndpoints.defaults.tokenEndpoint);
            return http.Response(
              '{"mfa_required":true,"username":"joao","message":"MFA required"}',
              200,
            );
          }),
        ),
        appLinksService: const EmptyAppLinksService(),
      );
      await controller.submitLogin(
        serverUrl: 'https://example.test',
        username: 'joao',
        password: 'secret',
      );

      expect(controller.showMfaInput, isTrue);
      expect(controller.isLoading, isFalse);
      expect(await storage.getUsername(), 'joao');
      controller.dispose();
    });

    test('handles successful SSO callback', () async {
      final storage = SecureStorageService();
      final appLinks = FakeAppLinksService();
      final controller = LoginController(
        authCoordinator: _repository(
          storage: storage,
          client: MockClient((request) async {
            if (request.url.path == ApiEndpoints.defaults.profileEndpoint) {
              return http.Response('{"id":1}', 200);
            }
            expect(
              request.url.path,
              '${ApiEndpoints.defaults.idpSessionTokenExchangeEndpoint}/session-1/tokens',
            );
            return http.Response(
              '{"access_token":"access-1","refresh_token":"refresh-1","session_id":"session-2","expires_in":3600}',
              200,
            );
          }),
        ),
        appLinksService: appLinks,
      );
      final loginCompleted = Completer<void>();
      controller.startSsoCallbackListener(
        onLoginSuccess: loginCompleted.complete,
        onError: (error) => fail(error.toString()),
      );

      await controller.beginSsoLogin(
        const IdentityProviderFixture().provider,
        serverUrl: 'https://example.test',
      );
      appLinks.add(
        Uri.parse('endurain://auth/sso/callback?session_id=session-1'),
      );
      await loginCompleted.future.timeout(const Duration(seconds: 1));

      final session = await AuthSessionStore(storage: storage).readSession();
      expect(session?.accessToken, 'access-1');
      expect(session?.refreshToken, 'refresh-1');
      controller.dispose();
      await appLinks.close();
    });

    test('reports SSO callback errors without exchanging tokens', () async {
      final storage = SecureStorageService();
      final appLinks = FakeAppLinksService();
      final errors = <Object>[];
      final controller = LoginController(
        authCoordinator: _repository(
          storage: storage,
          client: MockClient((request) async {
            fail('No HTTP request expected for callback error.');
          }),
        ),
        appLinksService: appLinks,
      );
      controller.startSsoCallbackListener(
        onLoginSuccess: () => fail('Login should not complete.'),
        onError: errors.add,
      );

      appLinks.add(
        Uri.parse('endurain://auth/sso/callback?error=access_denied'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(errors.single, 'access_denied');
      expect(controller.isLoading, isFalse);
      expect(await storage.getAccessToken(), isNull);
      controller.dispose();
      await appLinks.close();
    });

    test('reports SSO callbacks missing a session id', () async {
      final appLinks = FakeAppLinksService();
      final errors = <Object>[];
      final controller = LoginController(
        authCoordinator: _repository(
          storage: SecureStorageService(),
          client: MockClient((request) async {
            fail('No HTTP request expected without a session id.');
          }),
        ),
        appLinksService: appLinks,
      );
      controller.startSsoCallbackListener(
        onLoginSuccess: () => fail('Login should not complete.'),
        onError: errors.add,
      );

      appLinks.add(Uri.parse('endurain://auth/sso/callback'));
      await Future<void>.delayed(Duration.zero);

      expect(
        errors.single,
        isA<AppException>().having(
          (exception) => exception.code,
          'code',
          AppErrorCode.noSessionIdReceived,
        ),
      );
      expect(controller.isLoading, isFalse);
      controller.dispose();
      await appLinks.close();
    });

    test('auto-redirects to a single provider when configured', () async {
      final controller = LoginController(
        authCoordinator: _repository(
          storage: SecureStorageService(),
          client: MockClient((request) async {
            if (request.url.path ==
                ApiEndpoints.defaults.serverSettingsEndpoint) {
              return http.Response(
                '{"sso_enabled":true,"sso_auto_redirect":true,"local_login_enabled":true}',
                200,
              );
            }
            if (request.url.path == ApiEndpoints.defaults.idpListEndpoint) {
              return http.Response(
                '[{"id":1,"slug":"keycloak","name":"Keycloak","icon":"keycloak"}]',
                200,
              );
            }
            fail('Unexpected request to ${request.url}');
          }),
        ),
        appLinksService: const EmptyAppLinksService(),
      );

      final provider = await controller.submitServerUrl('https://example.test');

      expect(provider?.slug, 'keycloak');
      controller.dispose();
    });

    test('continues without providers when IdP listing fails', () async {
      final controller = LoginController(
        authCoordinator: _repository(
          storage: SecureStorageService(),
          client: MockClient((request) async {
            if (request.url.path ==
                ApiEndpoints.defaults.serverSettingsEndpoint) {
              return http.Response('{"sso_enabled":true}', 200);
            }
            return http.Response('{"detail":"boom"}', 500);
          }),
        ),
        appLinksService: const EmptyAppLinksService(),
      );

      final provider = await controller.submitServerUrl('https://example.test');

      expect(provider, isNull);
      expect(controller.isStep2, isTrue);
      expect(controller.availableIdPs, isEmpty);
      controller.dispose();
    });

    test('reports server settings failures', () async {
      final errors = <Object>[];
      final controller = LoginController(
        authCoordinator: _repository(
          storage: SecureStorageService(),
          client: MockClient((request) async {
            return http.Response('{"detail":"offline"}', 500);
          }),
        ),
        appLinksService: const EmptyAppLinksService(),
      );
      controller.startSsoCallbackListener(
        onLoginSuccess: () => fail('Login should not complete.'),
        onError: errors.add,
      );

      final provider = await controller.submitServerUrl('https://example.test');

      expect(provider, isNull);
      expect(controller.isStep2, isFalse);
      expect(controller.isLoading, isFalse);
      expect(errors, hasLength(1));
      controller.dispose();
    });

    test('builds an OAuth URL with the PKCE challenge', () async {
      final controller = LoginController(
        authCoordinator: _repository(
          storage: SecureStorageService(),
          client: MockClient((request) async {
            fail('initiateOAuth builds the URL without an HTTP call.');
          }),
        ),
        appLinksService: const EmptyAppLinksService(),
      );

      final oauthUrl = await controller.beginSsoLogin(
        const IdentityProviderFixture().provider,
        serverUrl: 'https://example.test',
      );

      expect(oauthUrl, isNotNull);
      final parsed = Uri.parse(oauthUrl!);
      expect(parsed.path, '${ApiEndpoints.defaults.idpLoginEndpoint}/keycloak');
      expect(parsed.queryParameters['code_challenge'], isNotEmpty);
      expect(parsed.queryParameters['code_challenge_method'], 'S256');
      expect(controller.isLoading, isFalse);
      controller.dispose();
    });

    test('reports SSO initiation failures', () async {
      final errors = <Object>[];
      final controller = LoginController(
        authCoordinator: _repository(
          storage: SecureStorageService(),
          client: MockClient((request) async {
            fail('No HTTP request expected without a server URL.');
          }),
        ),
        appLinksService: const EmptyAppLinksService(),
      );
      controller.startSsoCallbackListener(
        onLoginSuccess: () => fail('Login should not complete.'),
        onError: errors.add,
      );
      // No server URL configured, so initiateOAuth throws.
      final oauthUrl = await controller.beginSsoLogin(
        const IdentityProviderFixture().provider,
        serverUrl: '',
      );

      expect(oauthUrl, isNull);
      expect(controller.isLoading, isFalse);
      expect(
        errors.single,
        isA<AppException>().having(
          (exception) => exception.code,
          'code',
          AppErrorCode.serverUrlNotConfigured,
        ),
      );
      controller.dispose();
    });

    test('completes login when no MFA is required', () async {
      final storage = SecureStorageService();
      final loginCompleted = Completer<void>();
      final controller = LoginController(
        authCoordinator: _repository(
          storage: storage,
          client: MockClient((request) async {
            if (request.url.path == ApiEndpoints.defaults.tokenEndpoint) {
              return http.Response('{"session_id":"session-1"}', 200);
            }
            if (request.url.path == ApiEndpoints.defaults.profileEndpoint) {
              return http.Response('{"id":1}', 200);
            }
            return http.Response(
              '{"access_token":"access-1","refresh_token":"refresh-1","session_id":"session-2","expires_in":3600}',
              200,
            );
          }),
        ),
        appLinksService: const EmptyAppLinksService(),
      );
      controller.startSsoCallbackListener(
        onLoginSuccess: loginCompleted.complete,
        onError: (error) => fail(error.toString()),
      );
      await controller.submitLogin(
        serverUrl: 'https://example.test',
        username: 'joao',
        password: 'secret',
      );
      await loginCompleted.future.timeout(const Duration(seconds: 1));

      expect(
        (await AuthSessionStore(storage: storage).readSession())?.accessToken,
        'access-1',
      );
      controller.dispose();
    });

    test('reports login failures', () async {
      final errors = <Object>[];
      final controller = LoginController(
        authCoordinator: _repository(
          storage: SecureStorageService(),
          client: MockClient((request) async {
            return http.Response('{"detail":"Bad credentials"}', 401);
          }),
        ),
        appLinksService: const EmptyAppLinksService(),
      );
      controller.startSsoCallbackListener(
        onLoginSuccess: () => fail('Login should not complete.'),
        onError: errors.add,
      );
      await controller.submitLogin(
        serverUrl: 'https://example.test',
        username: 'joao',
        password: 'wrong',
      );

      expect(controller.isLoading, isFalse);
      expect(errors, hasLength(1));
      controller.dispose();
    });

    test('completes MFA verification', () async {
      final storage = SecureStorageService();
      final loginCompleted = Completer<void>();
      final controller = LoginController(
        authCoordinator: _repository(
          storage: storage,
          client: MockClient((request) async {
            if (request.url.path == ApiEndpoints.defaults.tokenEndpoint) {
              return http.Response(
                '{"mfa_required":true,"username":"joao"}',
                200,
              );
            }
            if (request.url.path == ApiEndpoints.defaults.mfaVerifyEndpoint) {
              return http.Response('{"session_id":"session-1"}', 200);
            }
            if (request.url.path == ApiEndpoints.defaults.profileEndpoint) {
              return http.Response('{"id":1}', 200);
            }
            return http.Response(
              '{"access_token":"access-1","refresh_token":"refresh-1","session_id":"session-2","expires_in":3600}',
              200,
            );
          }),
        ),
        appLinksService: const EmptyAppLinksService(),
      );
      controller.startSsoCallbackListener(
        onLoginSuccess: loginCompleted.complete,
        onError: (error) => fail(error.toString()),
      );
      await controller.submitLogin(
        serverUrl: 'https://example.test',
        username: 'joao',
        password: 'secret',
      );
      expect(controller.showMfaInput, isTrue);

      await controller.submitMfa('123456');
      await loginCompleted.future.timeout(const Duration(seconds: 1));

      expect(
        (await AuthSessionStore(storage: storage).readSession())?.accessToken,
        'access-1',
      );
      controller.dispose();
    });

    test('rejects MFA submission without a stored username', () async {
      final errors = <Object>[];
      final controller = LoginController(
        authCoordinator: _repository(
          storage: SecureStorageService(),
          client: MockClient((request) async {
            fail('No request should be made without an MFA username.');
          }),
        ),
        appLinksService: const EmptyAppLinksService(),
      );
      controller.startSsoCallbackListener(
        onLoginSuccess: () => fail('Login should not complete.'),
        onError: errors.add,
      );

      await controller.submitMfa('123456');

      expect(
        errors.single,
        isA<AppException>().having(
          (exception) => exception.code,
          'code',
          AppErrorCode.noSessionIdReceived,
        ),
      );
      controller.dispose();
    });

    test('reports SSO callback exchange failures', () async {
      final appLinks = FakeAppLinksService();
      final errors = <Object>[];
      final controller = LoginController(
        authCoordinator: _repository(
          storage: SecureStorageService(),
          client: MockClient((request) async {
            return http.Response('{"detail":"exchange failed"}', 400);
          }),
        ),
        appLinksService: appLinks,
      );
      controller.startSsoCallbackListener(
        onLoginSuccess: () => fail('Login should not complete.'),
        onError: errors.add,
      );

      appLinks.add(
        Uri.parse('endurain://auth/sso/callback?session_id=session-1'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(errors, hasLength(1));
      expect(controller.isLoading, isFalse);
      controller.dispose();
      await appLinks.close();
    });

    test('toggles step, MFA, and password visibility state', () async {
      final controller = LoginController(
        authCoordinator: _repository(
          storage: SecureStorageService(),
          client: MockClient((request) async {
            if (request.url.path ==
                ApiEndpoints.defaults.serverSettingsEndpoint) {
              return http.Response(
                '{"sso_enabled":true,"local_login_enabled":true}',
                200,
              );
            }
            if (request.url.path == ApiEndpoints.defaults.idpListEndpoint) {
              return http.Response(
                '[{"id":1,"slug":"keycloak","name":"Keycloak","icon":"keycloak"}]',
                200,
              );
            }
            if (request.url.path == ApiEndpoints.defaults.tokenEndpoint) {
              return http.Response(
                '{"mfa_required":true,"username":"joao","message":"MFA"}',
                200,
              );
            }
            fail('Unexpected request to ${request.url}');
          }),
        ),
        appLinksService: const EmptyAppLinksService(),
      );

      await controller.submitServerUrl('https://example.test');
      expect(controller.isStep2, isTrue);
      expect(controller.availableIdPs, isNotEmpty);
      expect(controller.serverSettings, isNotNull);

      await controller.submitLogin(
        serverUrl: 'https://example.test',
        username: 'joao',
        password: 'secret',
      );
      expect(controller.showMfaInput, isTrue);

      controller.backToServerStep();
      expect(controller.isStep2, isFalse);
      expect(controller.availableIdPs, isEmpty);
      expect(controller.serverSettings, isNull);

      controller.backFromMfa();
      expect(controller.showMfaInput, isFalse);

      controller.setPasswordVisible(true);
      expect(controller.obscurePassword, isFalse);
      controller.setPasswordVisible(false);
      expect(controller.obscurePassword, isTrue);

      controller.dispose();
    });

    group('isInsecureHttpUrl', () {
      LoginController makeController() => LoginController(
        authCoordinator: _repository(
          storage: SecureStorageService(),
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
        appLinksService: const EmptyAppLinksService(),
      );

      test('is false when URL is https', () {
        final controller = makeController();
        expect(controller.isInsecureHttpUrl('https://example.test'), isFalse);
        controller.dispose();
      });

      test('is true when URL is http', () {
        final controller = makeController();
        expect(controller.isInsecureHttpUrl('http://example.test'), isTrue);
        controller.dispose();
      });

      test('is false for empty or invalid input', () {
        final controller = makeController();
        expect(controller.isInsecureHttpUrl(''), isFalse);
        expect(controller.isInsecureHttpUrl('not-a-url'), isFalse);
        controller.dispose();
      });

      test('is false for an http URL targeting the cloud origin', () {
        final controller = LoginController(
          authCoordinator: _repository(
            storage: SecureStorageService(),
            client: MockClient((_) async => http.Response('{}', 200)),
          ),
          appLinksService: const EmptyAppLinksService(),
          config: const AppConfig(cloudBaseUrl: 'https://example.test'),
        );
        expect(controller.isInsecureHttpUrl('http://example.test'), isFalse);
        controller.dispose();
      });
    });

    test('commits map settings only after authentication succeeds', () async {
      final storage = SecureStorageService();
      final prefs = FakePreferencesStore();
      final mapRepo = MapSettingsRepository(preferences: prefs);
      final controller = LoginController(
        authCoordinator: _repository(
          storage: storage,
          client: MockClient((request) async {
            if (request.url.path ==
                ApiEndpoints.defaults.serverSettingsEndpoint) {
              return http.Response(
                '{"tileserver_url":"https://tiles.test/{z}/{x}/{y}.png",'
                '"tileserver_attribution":"OSM",'
                '"map_background_color":"#001122"}',
                200,
              );
            }
            if (request.url.path == ApiEndpoints.defaults.tokenEndpoint) {
              return http.Response('{"session_id":"session-1"}', 200);
            }
            if (request.url.path ==
                '${ApiEndpoints.defaults.idpSessionTokenExchangeEndpoint}/session-1/tokens') {
              return http.Response(
                '{"access_token":"access-1","refresh_token":"refresh-1",'
                '"session_id":"session-2","expires_in":3600}',
                200,
              );
            }
            if (request.url.path == ApiEndpoints.defaults.profileEndpoint) {
              return http.Response('{"id":1}', 200);
            }
            if (request.url.path == ApiEndpoints.defaults.idpListEndpoint) {
              return http.Response('[]', 200);
            }
            fail('Unexpected request to ${request.url}');
          }),
        ),
        appLinksService: const EmptyAppLinksService(),
        mapSettingsRepository: mapRepo,
      );
      await controller.submitServerUrl('https://example.test');
      expect(
        await mapRepo.getTileServerUrl(origin: 'https://example.test'),
        MapConstants.defaultTileServerUrl,
      );

      await controller.submitLogin(
        serverUrl: 'https://example.test',
        username: 'joao',
        password: 'secret',
      );

      expect(
        await mapRepo.getTileServerUrl(origin: 'https://example.test'),
        'https://tiles.test/{z}/{x}/{y}.png',
      );
      controller.dispose();
    });
  });
}

AuthCoordinator _repository({
  required SecureStorageService storage,
  required http.Client client,
}) {
  return AuthCoordinator(
    authService: AuthService(storage: storage, httpClient: client),
    ssoService: SsoService(storage: storage, httpClient: client),
    serverSettingsService: ServerSettingsService(
      storage: storage,
      httpClient: client,
    ),
  );
}

class IdentityProviderFixture {
  const IdentityProviderFixture();

  core.IdentityProvider get provider => const core.IdentityProvider(
    id: 1,
    slug: 'keycloak',
    name: 'Keycloak',
    icon: 'keycloak',
  );
}
