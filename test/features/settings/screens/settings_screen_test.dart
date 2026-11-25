import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/services/platform/package_info_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/settings/controllers/locale_controller.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/features/settings/controllers/settings_controller.dart';
import 'package:endurain/features/settings/repositories/locale_settings_repository.dart';
import 'package:endurain/features/settings/repositories/measurement_settings_repository.dart';
import 'package:endurain/features/settings/screens/settings_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../helpers/fake_preferences_store.dart';
import '../../../helpers/fake_url_launcher_service.dart';
import '../../../helpers/widget_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'server_url': 'https://endurain.example.test',
    });
  });

  tearDown(PlatformUtils.debugResetOverrides);

  LocaleController buildLocaleController() => LocaleController(
    repository: LocaleSettingsRepository(preferences: FakePreferencesStore()),
  );

  SettingsController buildSettingsController() => SettingsController(
    packageInfoService: const _FakePackageInfoService(version: '1.2.3'),
    measurementSystemController: MeasurementSystemController(
      repository: MeasurementSettingsRepository(
        preferences: FakePreferencesStore(),
      ),
    ),
    secureStorage: SecureStorageService(),
  );

  testWidgets('SettingsScreen shows navigation and package version', (
    tester,
  ) async {
    // Tall enough that the lazy list builds every entry.
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final localeController = buildLocaleController();
    addTearDown(localeController.dispose);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: TestAppScope(
          child: SettingsScreen(
            controller: buildSettingsController(),
            localeController: localeController,
            urlLauncherService: FakeUrlLauncherService(launched: true),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsScreen), findsOneWidget);
    expect(find.text(l10n.serverSettings), findsOneWidget);
    expect(
      find.text(l10n.connectedToServer('https://endurain.example.test')),
      findsOneWidget,
    );
    expect(find.text(l10n.language), findsOneWidget);
    expect(find.text(l10n.languageSystemDefault), findsOneWidget);
    expect(find.text(l10n.activityHistoryTitle), findsOneWidget);
    // The GPX retention switch lives on the activity history screen now.
    expect(find.text(l10n.activityRetainUploadedGpx), findsNothing);
    expect(find.text(l10n.deviceAccessTitle), findsOneWidget);
    expect(find.text(l10n.diagnostics), findsOneWidget);
    expect(find.text(l10n.sourceCode), findsOneWidget);
    expect(find.text(l10n.sourceCodeSubtitle), findsOneWidget);
    expect(find.textContaining('Endurain • 1.2.3'), findsOneWidget);
    expect(find.text(l10n.endurainTrademarkNotice), findsOneWidget);
  });

  testWidgets('SettingsScreen groups entries under section headers', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final localeController = buildLocaleController();
    addTearDown(localeController.dispose);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: TestAppScope(
          child: SettingsScreen(
            controller: buildSettingsController(),
            localeController: localeController,
            urlLauncherService: FakeUrlLauncherService(launched: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    double top(String text) => tester.getTopLeft(find.text(text)).dy;

    // Each entry sits below its own section header and above the next one.
    final layout = <String, List<String>>{
      l10n.settingsSectionAccount: [l10n.serverSettings],
      l10n.settingsSectionGeneral: [
        l10n.language,
        l10n.unitsTitle,
        l10n.mapTilesSettingsTitle,
      ],
      l10n.settingsSectionRecording: [
        l10n.startCountdownSettingsTitle,
        l10n.activityAutoPauseTitle,
        l10n.audioAnnouncementsTitle,
      ],
      l10n.settingsSectionDevices: [l10n.sensorsTitle],
      l10n.settingsSectionData: [l10n.activityHistoryTitle],
      l10n.settingsSectionPrivacySupport: [
        l10n.deviceAccessTitle,
        l10n.diagnostics,
        l10n.sourceCode,
      ],
    };
    final headers = layout.keys.toList();
    for (var i = 0; i < headers.length; i++) {
      final header = headers[i];
      expect(find.text(header), findsOneWidget);
      for (final entry in layout[header]!) {
        expect(top(entry), greaterThan(top(header)), reason: entry);
        if (i + 1 < headers.length) {
          expect(top(entry), lessThan(top(headers[i + 1])), reason: entry);
        }
      }
    }
  });

  testWidgets('SettingsScreen opens the source code repository', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final localeController = buildLocaleController();
    addTearDown(localeController.dispose);
    final launcher = FakeUrlLauncherService(launched: true);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: TestAppScope(
          child: SettingsScreen(
            controller: buildSettingsController(),
            localeController: localeController,
            urlLauncherService: launcher,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text(l10n.sourceCode), 200);
    await tester.ensureVisible(find.text(l10n.sourceCode));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sourceCode));
    await tester.pumpAndSettle();

    expect(launcher.launchedUris, [
      Uri.parse('https://github.com/endurain-project'),
    ]);
  });

  testWidgets('SettingsScreen warns when the source code link fails', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final localeController = buildLocaleController();
    addTearDown(localeController.dispose);
    final launcher = FakeUrlLauncherService(launched: false);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: TestAppScope(
          child: SettingsScreen(
            controller: buildSettingsController(),
            localeController: localeController,
            urlLauncherService: launcher,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text(l10n.sourceCode), 200);
    await tester.ensureVisible(find.text(l10n.sourceCode));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.sourceCode));
    await tester.pumpAndSettle();

    expect(launcher.launchedUris, [
      Uri.parse('https://github.com/endurain-project'),
    ]);
    expect(find.text(l10n.openLinkFailed), findsOneWidget);
  });

  testWidgets('SettingsScreen shows a sign-in entry in guest mode', (
    tester,
  ) async {
    final localeController = buildLocaleController();
    addTearDown(localeController.dispose);

    var signInTapped = false;
    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: TestAppScope(
          child: SettingsScreen(
            isGuest: true,
            onSignIn: () => signInTapped = true,
            controller: buildSettingsController(),
            localeController: localeController,
            urlLauncherService: FakeUrlLauncherService(launched: true),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Guests see the connect-a-server entry instead of server settings.
    expect(find.text(l10n.signInConnectServer), findsOneWidget);
    expect(find.text(l10n.serverSettings), findsNothing);
    // Tile URLs are stored per server, so guests have no Map tiles entry.
    expect(find.text(l10n.mapTilesSettingsTitle), findsNothing);

    await tester.tap(find.text(l10n.signInConnectServer));
    await tester.pumpAndSettle();
    expect(signInTapped, isTrue);
  });
}

class _FakePackageInfoService extends PackageInfoService {
  const _FakePackageInfoService({required this.version});

  final String version;

  @override
  Future<PackageInfo> fromPlatform() async {
    return PackageInfo(
      appName: 'Endurain',
      packageName: 'com.endurain.mobile',
      version: version,
      buildNumber: '1',
    );
  }
}
