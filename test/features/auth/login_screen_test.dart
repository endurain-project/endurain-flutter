import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/services/server_settings_service.dart';
import 'package:endurain/core/services/sso_service.dart';
import 'package:endurain/core/services/url_launcher_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/auth/auth_coordinator.dart';
import 'package:endurain/features/auth/login_controller.dart';
import 'package:endurain/features/auth/login_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/fake_app_links_service.dart';
import '../../helpers/fake_url_launcher_service.dart';
import '../../helpers/widget_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  tearDown(PlatformUtils.debugResetOverrides);

  group('LoginScreen', () {
    testWidgets('validates server URL before loading auth options', (
      tester,
    ) async {
      final controller = _controller(
        client: MockClient((request) async {
          fail('Network should not be called for invalid form input.');
        }),
      );

      await tester.pumpWidget(_loginScreen(controller: controller));

      await tester.enterText(find.byType(TextFormField), 'not a url');
      await tester.tap(find.text(l10n.next));
      await tester.pump();

      expect(find.text(l10n.invalidUrl), findsOneWidget);

      controller.dispose();
    });

    testWidgets('loads local login and SSO options from server settings', (
      tester,
    ) async {
      final controller = _controller(client: _authOptionsClient());

      await tester.pumpWidget(_loginScreen(controller: controller));

      await tester.enterText(
        find.byType(TextFormField),
        'https://example.test',
      );
      await tester.tap(find.text(l10n.next));
      await tester.pumpAndSettle();

      expect(find.text(l10n.username), findsOneWidget);
      expect(find.text(l10n.password), findsOneWidget);
      expect(find.text(l10n.showPassword), findsOneWidget);
      expect(find.text(l10n.ssoSignInWith('Keycloak')), findsOneWidget);

      controller.dispose();
    });

    testWidgets('shows MFA step and validates empty MFA code', (tester) async {
      final controller = _controller(
        client: MockClient((request) async {
          if (request.url.path ==
              ApiEndpoints.defaults.serverSettingsEndpoint) {
            return http.Response(
              '{"sso_enabled":false,"local_login_enabled":true}',
              200,
            );
          }
          if (request.url.path == ApiEndpoints.defaults.tokenEndpoint) {
            return http.Response(
              '{"mfa_required":true,"username":"joao","message":"MFA required"}',
              200,
            );
          }
          fail('Unexpected request to ${request.url}');
        }),
      );

      await tester.pumpWidget(_loginScreen(controller: controller));
      await tester.enterText(
        find.byType(TextFormField),
        'https://example.test',
      );
      await tester.tap(find.text(l10n.next));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.username),
        'joao',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.password),
        'secret',
      );
      await tester.tap(find.widgetWithText(FilledButton, l10n.login));
      await tester.pumpAndSettle();

      expect(find.text(l10n.mfaTitle), findsOneWidget);
      expect(find.text(l10n.mfaCode), findsOneWidget);

      await tester.tap(find.text(l10n.verify));
      await tester.pumpAndSettle();

      expect(find.text(l10n.mfaCodeRequired), findsOneWidget);

      controller.dispose();
    });

    testWidgets('reports SSO browser launch failures', (tester) async {
      final launcher = FakeUrlLauncherService(launched: false);
      final controller = _controller(client: _authOptionsClient());

      await tester.pumpWidget(
        _loginScreen(controller: controller, urlLauncherService: launcher),
      );
      await tester.enterText(
        find.byType(TextFormField),
        'https://example.test',
      );
      await tester.tap(find.text(l10n.next));
      await tester.pumpAndSettle();

      final ssoButton = find.widgetWithText(
        FilledButton,
        l10n.ssoSignInWith('Keycloak'),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -220));
      await tester.pumpAndSettle();
      await tester.tap(ssoButton);
      await tester.pumpAndSettle();

      expect(launcher.launchedUris.single.toString(), contains('keycloak'));
      expect(find.text(l10n.ssoBrowserLaunchFailed), findsOneWidget);

      controller.dispose();
    });
    testWidgets('managed mode rejects http URL without showing HTTP warning', (
      tester,
    ) async {
      final controller = _controller(
        client: MockClient((request) async {
          fail('Network should not be called for http:// in managed mode.');
        }),
        config: const AppConfig(transportMode: AppTransportMode.managed),
      );

      await tester.pumpWidget(_loginScreen(controller: controller));

      await tester.enterText(find.byType(TextFormField), 'http://example.test');
      await tester.tap(find.text(l10n.next));
      await tester.pump();

      expect(find.text(l10n.invalidUrl), findsOneWidget);

      controller.dispose();
    });
  });
}

Widget _loginScreen({
  required LoginController controller,
  UrlLauncherService urlLauncherService = const UrlLauncherService(),
}) {
  return TestMaterialApp(
    child: LoginScreen(
      controller: controller,
      urlLauncherService: urlLauncherService,
    ),
  );
}

LoginController _controller({
  required http.Client client,
  AppConfig config = AppConfig.defaults,
}) {
  final storage = SecureStorageService();
  return LoginController(
    authCoordinator: AuthCoordinator(
      authService: AuthService(storage: storage, httpClient: client),
      ssoService: SsoService(storage: storage, httpClient: client),
      serverSettingsService: ServerSettingsService(
        storage: storage,
        httpClient: client,
      ),
    ),
    appLinksService: const EmptyAppLinksService(),
    config: config,
  );
}

MockClient _authOptionsClient() {
  return MockClient((request) async {
    if (request.url.path == ApiEndpoints.defaults.serverSettingsEndpoint) {
      return http.Response(
        '{"sso_enabled":true,"local_login_enabled":true}',
        200,
      );
    }
    if (request.url.path == ApiEndpoints.defaults.idpListEndpoint) {
      return http.Response(
        '[{"id":1,"slug":"keycloak","name":"Keycloak","icon":""}]',
        200,
      );
    }
    fail('Unexpected request to ${request.url}');
  });
}
