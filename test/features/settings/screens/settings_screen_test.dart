import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/core/services/package_info_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/settings/screens/settings_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  final l10n = AppLocalizationsEn();

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
  });

  tearDown(PlatformUtils.debugResetOverrides);

  testWidgets('SettingsScreen shows navigation and package version', (
    tester,
  ) async {
    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: SettingsScreen(
          packageInfoService: const _FakePackageInfoService(version: '1.2.3'),
          activityRetentionSettings: _FakeActivityRetentionSettings(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsScreen), findsOneWidget);
    expect(find.text(l10n.serverSettings), findsOneWidget);
    expect(find.text(l10n.activityHistoryTitle), findsOneWidget);
    expect(find.text(l10n.activityRetainUploadedGpx), findsOneWidget);
    expect(find.byIcon(Icons.description), findsOneWidget);
    expect(
      tester.getTopLeft(find.byIcon(Icons.description)).dx,
      tester.getTopLeft(find.byIcon(Icons.dns)).dx,
    );
    expect(find.text(l10n.diagnostics), findsOneWidget);
    expect(find.textContaining('Endurain • 1.2.3'), findsOneWidget);
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
