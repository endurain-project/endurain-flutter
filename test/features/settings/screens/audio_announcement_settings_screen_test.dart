import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_config.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';
import 'package:endurain/features/activity/repositories/audio_announcement_settings_repository.dart';
import 'package:endurain/features/activity/services/audio_announcement_preview_adapter.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/features/settings/controllers/audio_announcement_settings_controller.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/features/settings/repositories/measurement_settings_repository.dart';
import 'package:endurain/features/settings/screens/audio_announcement_settings_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();
  late AudioAnnouncementSettingsController controller;
  late MeasurementSystemController measurementController;
  late _RecordingPreviewAdapter previewAdapter;

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
    previewAdapter = _RecordingPreviewAdapter();
    controller = AudioAnnouncementSettingsController(
      repository: AudioAnnouncementSettingsRepository(
        preferences: FakePreferencesStore(),
      ),
      previewAdapter: previewAdapter,
    );
    measurementController = MeasurementSystemController(
      repository: MeasurementSettingsRepository(
        preferences: FakePreferencesStore(),
      ),
    );
  });

  tearDown(() {
    PlatformUtils.debugResetOverrides();
    controller.dispose();
    measurementController.dispose();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    MeasurementSystem measurementSystem = MeasurementSystem.metric,
  }) async {
    await measurementController.setPreference(measurementSystem);
    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        locale: const Locale('en'),
        home: AudioAnnouncementSettingsScreen(
          controller: controller,
          measurementSystemController: measurementController,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the master switch off and ducking on by default', (
    tester,
  ) async {
    await pumpScreen(tester);

    final masterSwitch = tester.widget<AdaptiveSwitchListTile>(
      find.widgetWithText(
        AdaptiveSwitchListTile,
        l10n.audioAnnouncementsMasterSwitch,
      ),
    );
    final duckSwitch = tester.widget<AdaptiveSwitchListTile>(
      find.widgetWithText(
        AdaptiveSwitchListTile,
        l10n.audioAnnouncementsDuckSwitch,
      ),
    );

    expect(masterSwitch.value, isFalse);
    expect(duckSwitch.value, isTrue);
  });

  testWidgets('shows one interval card per activity type', (tester) async {
    await pumpScreen(tester);

    for (final type in ActivityType.values) {
      final label = find.text(type.localizedLabel(l10n));
      await tester.scrollUntilVisible(label, 200);
      expect(label, findsOneWidget);
    }
  });

  testWidgets('toggling the master switch updates the controller', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(
      find.widgetWithText(
        AdaptiveSwitchListTile,
        l10n.audioAnnouncementsMasterSwitch,
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.settings.masterEnabled, isTrue);
  });

  testWidgets('shows the default 1.0 km interval for running', (tester) async {
    await pumpScreen(tester);

    expect(
      find.text(l10n.audioAnnouncementsIntervalDistance('1.0', 'km')),
      findsWidgets,
    );
  });

  testWidgets('shows the default 5.0 km interval for cycling', (tester) async {
    await pumpScreen(tester);

    final rideLabel = find.text(ActivityType.ride.localizedLabel(l10n));
    await tester.scrollUntilVisible(rideLabel, 200);

    expect(
      find.text(l10n.audioAnnouncementsIntervalDistance('5.0', 'km')),
      findsOneWidget,
    );
  });

  testWidgets('uses one and five mile imperial defaults', (tester) async {
    await pumpScreen(tester, measurementSystem: MeasurementSystem.imperial);

    expect(
      find.text(l10n.audioAnnouncementsIntervalDistance('1.0', 'mi')),
      findsWidgets,
    );
    final rideLabel = find.text(ActivityType.ride.localizedLabel(l10n));
    await tester.scrollUntilVisible(rideLabel, 200);
    expect(
      find.text(l10n.audioAnnouncementsIntervalDistance('5.0', 'mi')),
      findsOneWidget,
    );
  });

  testWidgets('other is disabled by default and can be enabled', (
    tester,
  ) async {
    await controller.setMasterEnabled(true);
    await pumpScreen(tester);

    final otherLabel = ActivityType.other.localizedLabel(l10n);
    final otherSwitchFinder = find.widgetWithText(
      AdaptiveSwitchListTile,
      otherLabel,
    );
    await tester.scrollUntilVisible(otherSwitchFinder, 200);
    await tester.ensureVisible(otherSwitchFinder);
    await tester.pumpAndSettle();
    expect(
      tester.widget<AdaptiveSwitchListTile>(otherSwitchFinder).value,
      isFalse,
    );

    await tester.tap(otherSwitchFinder);
    await tester.pumpAndSettle();

    expect(controller.settings.intervalFor(ActivityType.other).enabled, isTrue);
  });

  testWidgets('increasing the interval steps by half a kilometre', (
    tester,
  ) async {
    await controller.setMasterEnabled(true);
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();

    expect(
      controller.settings.intervalFor(ActivityType.run).distanceMeters,
      1500,
    );
  });

  testWidgets('switching to time updates the subtitle', (tester) async {
    await controller.setMasterEnabled(true);
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.audioAnnouncementsByTime).first);
    await tester.pumpAndSettle();

    expect(
      controller.settings.intervalFor(ActivityType.run).unit,
      AudioAnnouncementIntervalUnit.time,
    );
    expect(find.text(l10n.audioAnnouncementsIntervalTime('5')), findsOneWidget);
  });

  testWidgets('states that changes apply to the next recording', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(
      find.text(l10n.audioAnnouncementsAppliesNextRecording),
      findsOneWidget,
    );
  });

  testWidgets('the preview speaks the interval configured for that activity', (
    tester,
  ) async {
    await controller.setMasterEnabled(true);
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.audioAnnouncementsPreview).first);
    await tester.pumpAndSettle();

    expect(previewAdapter.configs, hasLength(1));
    final config = previewAdapter.configs.single;
    expect(config.distanceIntervalMeters, 1000);
    expect(config.metricLabel, l10n.activityStatPace);
  });

  testWidgets('a rejected preview surfaces a message instead of failing', (
    tester,
  ) async {
    previewAdapter.shouldThrow = true;
    await controller.setMasterEnabled(true);
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.audioAnnouncementsPreview).first);
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.audioAnnouncementsPreviewUnavailable),
      findsOneWidget,
    );
  });
}

class _RecordingPreviewAdapter implements AudioAnnouncementPreviewAdapter {
  final List<AudioAnnouncementConfig> configs = [];
  bool shouldThrow = false;

  @override
  Future<void> speakPreview(AudioAnnouncementConfig config) async {
    if (shouldThrow) {
      throw StateError('no speech engine');
    }
    configs.add(config);
  }
}
