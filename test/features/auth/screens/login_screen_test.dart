import 'dart:convert';

import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/auth/server_settings_service.dart';
import 'package:endurain/core/auth/sso_service.dart';
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/services/platform/url_launcher_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/auth/controllers/login_controller.dart';
import 'package:endurain/features/auth/screens/login_screen.dart';
import 'package:endurain/features/auth/services/auth_coordinator.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fake_app_links_service.dart';
import '../../../helpers/fake_url_launcher_service.dart';
import '../../../helpers/widget_test_app.dart';

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

      await tester.enterText(find.byType(TextFormField), 'example.test');
      await tester.tap(find.text(l10n.next));
      await tester.pumpAndSettle();

      expect(find.text(l10n.username), findsOneWidget);
      expect(find.text(l10n.password), findsOneWidget);
      expect(find.text(l10n.showPassword), findsOneWidget);
      expect(find.text(l10n.ssoSignInWith('Keycloak')), findsOneWidget);

      controller.dispose();
    });

    testWidgets('uses the selected HTTP protocol for a self-hosted server', (
      tester,
    ) async {
      Uri? requestedUri;
      final controller = _controller(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            '{"sso_enabled":false,"local_login_enabled":true}',
            200,
          );
        }),
      );

      await tester.pumpWidget(_loginScreen(controller: controller));
      await tester.enterText(find.byType(TextFormField), 'example.test');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('HTTP').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.next));
      await tester.pumpAndSettle();
      expect(find.text(l10n.warnHttpServerUrlTitle), findsOneWidget);

      await tester.tap(find.text(l10n.warnHttpServerUrlConfirm));
      await tester.pumpAndSettle();

      expect(requestedUri?.scheme, 'http');
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
              '{"next_step":"mfa","mfa_challenge":"challenge-1"}',
              200,
            );
          }
          fail('Unexpected request to ${request.url}');
        }),
      );

      await tester.pumpWidget(_loginScreen(controller: controller));
      await tester.enterText(find.byType(TextFormField), 'example.test');
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
      expect(find.text(l10n.mfaCodeHint), findsOneWidget);
      // The server named no methods, so it offers no backup code.
      expect(find.text(l10n.mfaUseBackupCode), findsNothing);

      await tester.tap(find.text(l10n.verify));
      await tester.pumpAndSettle();

      expect(find.text(l10n.mfaCodeRequired), findsOneWidget);

      controller.dispose();
    });

    testWidgets('sends six digits on its own and shows why they failed', (
      tester,
    ) async {
      final submitted = <String>[];
      final controller = _controller(client: _mfaClient(submitted));
      await _reachMfaStep(tester, controller, l10n);

      // Letters and separators are dropped; the sixth digit sends the code.
      await tester.enterText(find.byType(TextField), '12a3 45-6789');
      await tester.pumpAndSettle();

      expect(submitted, ['123456']);
      expect(find.text(l10n.mfaTitle), findsOneWidget);
      expect(
        find.text(l10n.errorMfaVerificationFailedWithDetails('Invalid code')),
        findsOneWidget,
      );
      expect(_mfaInput(tester).controller!.text, isEmpty);
      // Inline, not in a dialog.
      expect(find.text(l10n.ok), findsNothing);

      // Typing again hides the reason.
      await tester.enterText(find.byType(TextField), '1');
      await tester.pump();
      expect(
        find.text(l10n.errorMfaVerificationFailedWithDetails('Invalid code')),
        findsNothing,
      );

      controller.dispose();
    });

    testWidgets(
      'sends eight backup code characters on their own, with a dash',
      (tester) async {
        final submitted = <String>[];
        final controller = _controller(client: _mfaClient(submitted));
        await _reachMfaStep(tester, controller, l10n);

        await tester.enterText(find.byType(TextField), '12');
        await tester.tap(find.text(l10n.mfaUseBackupCode));
        await tester.pumpAndSettle();

        expect(find.text(l10n.mfaBackupCodeHint), findsOneWidget);
        expect(_mfaInput(tester).controller!.text, isEmpty);

        await tester.enterText(find.byType(TextField), 'a3k9-7bd');
        await tester.pumpAndSettle();
        expect(_mfaInput(tester).controller!.text, 'A3K97BD');
        expect(submitted, isEmpty);

        await tester.enterText(find.byType(TextField), 'a3k9-7bdf-xyz');
        await tester.pumpAndSettle();
        expect(submitted, ['A3K9-7BDF']);

        controller.dispose();
      },
    );

    testWidgets('an incomplete code is not sent', (tester) async {
      final submitted = <String>[];
      final controller = _controller(client: _mfaClient(submitted));
      await _reachMfaStep(tester, controller, l10n);

      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text(l10n.verify));
      await tester.pumpAndSettle();

      expect(find.text(l10n.mfaCodeRequired), findsOneWidget);
      expect(submitted, isEmpty);

      controller.dispose();
    });

    testWidgets(
      'a lost sign-in session returns to the credentials in a dialog',
      (tester) async {
        final submitted = <String>[];
        final controller = _controller(
          client: _mfaClient(submitted, verifyStatus: 401),
        );
        await _reachMfaStep(tester, controller, l10n);
        await tester.tap(find.text(l10n.mfaUseBackupCode));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'A3K97BDF');
        await tester.pumpAndSettle();

        expect(submitted, ['A3K9-7BDF']);
        expect(find.text(l10n.errorMfaSessionMissing), findsOneWidget);
        expect(find.text(l10n.ok), findsOneWidget);
        await tester.tap(find.text(l10n.ok));
        await tester.pumpAndSettle();
        expect(find.text(l10n.mfaTitle), findsNothing);
        expect(
          find.widgetWithText(TextFormField, l10n.username),
          findsOneWidget,
        );

        // The next sign-in starts again on an authenticator code.
        await tester.tap(find.widgetWithText(FilledButton, l10n.login));
        await tester.pumpAndSettle();
        expect(find.text(l10n.mfaCodeHint), findsOneWidget);
        expect(find.text(l10n.mfaBackupCodeHint), findsNothing);

        controller.dispose();
      },
    );

    testWidgets('shows the password-change step and checks the repeat', (
      tester,
    ) async {
      final changes = <Object?>[];
      final controller = _controller(
        client: MockClient((request) async {
          final path = request.url.path;
          if (path == ApiEndpoints.defaults.serverSettingsEndpoint) {
            return http.Response(
              '{"sso_enabled":false,"local_login_enabled":true}',
              200,
            );
          }
          if (path == ApiEndpoints.defaults.tokenEndpoint) {
            return http.Response(
              '{"next_step":"password_change",'
              '"password_change_challenge":"change-1"}',
              200,
            );
          }
          if (path == ApiEndpoints.defaults.passwordChangeEndpoint) {
            changes.add(jsonDecode(request.body));
            return http.Response('{"detail":"Password is too short"}', 422);
          }
          fail('Unexpected request to ${request.url}');
        }),
      );

      await tester.pumpWidget(_loginScreen(controller: controller));
      await tester.enterText(find.byType(TextFormField), 'example.test');
      await tester.tap(find.text(l10n.next));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.username),
        'joao',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.password),
        'set-by-admin',
      );
      await tester.tap(find.widgetWithText(FilledButton, l10n.login));
      await tester.pumpAndSettle();

      expect(find.text(l10n.passwordChangeTitle), findsOneWidget);
      expect(find.text(l10n.passwordChangeMessage), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.newPassword),
        'first try',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.confirmNewPassword),
        'different',
      );
      await tester.tap(find.widgetWithText(FilledButton, l10n.changePassword));
      await tester.pumpAndSettle();

      expect(find.text(l10n.passwordsDoNotMatch), findsOneWidget);
      expect(changes, isEmpty);

      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.confirmNewPassword),
        'first try',
      );
      await tester.tap(find.widgetWithText(FilledButton, l10n.changePassword));
      await tester.pumpAndSettle();

      expect(changes, [
        {'password_change_challenge': 'change-1', 'password': 'first try'},
      ]);
      expect(
        find.text(
          l10n.errorPasswordChangeFailedWithDetails('Password is too short'),
        ),
        findsOneWidget,
      );

      controller.dispose();
    });

    testWidgets('reports SSO browser launch failures', (tester) async {
      final launcher = FakeUrlLauncherService(launched: false);
      final controller = _controller(client: _authOptionsClient());

      await tester.pumpWidget(
        _loginScreen(controller: controller, urlLauncherService: launcher),
      );
      await tester.enterText(find.byType(TextFormField), 'example.test');
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
    testWidgets('rejects http cloud URL without showing HTTP warning', (
      tester,
    ) async {
      final controller = _controller(
        client: MockClient((request) async {
          fail('Network should not be called for http:// to the cloud origin.');
        }),
        config: const AppConfig(cloudBaseUrl: 'https://example.test'),
      );

      await tester.pumpWidget(_loginScreen(controller: controller));

      await tester.enterText(find.byType(TextFormField), 'example.test');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('HTTP').last);
      await tester.pumpAndSettle();
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
  VoidCallback? onCancel,
}) {
  return TestMaterialApp(
    child: LoginScreen(
      controller: controller,
      urlLauncherService: urlLauncherService,
      onCancel: onCancel,
    ),
  );
}

/// A server that asks for MFA (TOTP or backup code) and records each code
/// sent to it, then rejects it: as a wrong code, or with a `401` as a dead
/// challenge.
MockClient _mfaClient(List<String> submitted, {int verifyStatus = 400}) {
  return MockClient((request) async {
    final path = request.url.path;
    if (path == ApiEndpoints.defaults.serverSettingsEndpoint) {
      return http.Response(
        '{"sso_enabled":false,"local_login_enabled":true}',
        200,
      );
    }
    if (path == ApiEndpoints.defaults.tokenEndpoint) {
      return http.Response(
        '{"next_step":"mfa","mfa_challenge":"${'c' * 43}",'
        '"methods":["totp","backup_code"]}',
        200,
      );
    }
    if (path == ApiEndpoints.defaults.mfaVerifyEndpoint) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      submitted.add(body['mfa_code'] as String);
      return http.Response('{"detail":"Invalid code"}', verifyStatus);
    }
    fail('Unexpected request to ${request.url}');
  });
}

Future<void> _reachMfaStep(
  WidgetTester tester,
  LoginController controller,
  AppLocalizationsEn l10n,
) async {
  await tester.pumpWidget(_loginScreen(controller: controller));
  await tester.enterText(find.byType(TextFormField), 'example.test');
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
}

TextField _mfaInput(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

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
