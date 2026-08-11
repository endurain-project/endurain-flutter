import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/core/services/platform/package_info_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/settings/controllers/locale_controller.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/features/settings/controllers/settings_controller.dart';
import 'package:endurain/features/settings/repositories/measurement_settings_repository.dart';
import 'package:endurain/features/settings/repositories/locale_settings_repository.dart';
import 'package:endurain/features/settings/screens/settings_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
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

  SettingsController buildSettingsController({
    ActivityRetentionSettingsRepository? retention,
  }) => SettingsController(
    packageInfoService: const _FakePackageInfoService(version: '1.2.3'),
    retentionSettingsRepository: retention ?? _FakeActivityRetentionSettings(),
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
    expect(find.text(l10n.activityRetainUploadedGpx), findsOneWidget);
    expect(find.text(l10n.deviceAccessTitle), findsOneWidget);
    expect(find.byIcon(Icons.description), findsOneWidget);
    expect(
      tester.getTopLeft(find.byIcon(Icons.description)).dx,
      tester.getTopLeft(find.byIcon(Icons.dns)).dx,
    );
    expect(find.text(l10n.diagnostics), findsOneWidget);
    expect(find.text(l10n.sourceCode), findsOneWidget);
    expect(find.text(l10n.sourceCodeSubtitle), findsOneWidget);
    expect(find.textContaining('Endurain • 1.2.3'), findsOneWidget);
    expect(find.text(l10n.endurainTrademarkNotice), findsOneWidget);
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
      Uri.parse('https://codeberg.org/endurain-project'),
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
      Uri.parse('https://codeberg.org/endurain-project'),
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

    await tester.tap(find.text(l10n.signInConnectServer));
    await tester.pumpAndSettle();
    expect(signInTapped, isTrue);
  });
}

class _FakeActivityRetentionSettings
    extends ActivityRetentionSettingsRepository {
  _FakeActivityRetentionSettings() : super(storage: SecureStorageService());

  var retainUploadedGpx = true;

  @override
  Future<bool> isRetainUploadedGpxEnabled() async => retainUploadedGpx;

  @override
  Future<void> setRetainUploadedGpxEnabled(bool enabled) async {
    retainUploadedGpx = enabled;
  }
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
