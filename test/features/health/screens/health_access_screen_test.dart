import 'package:endurain/core/services/platform/health_connect_settings_service.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/screens/health_access_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_health_auto_sync_service.dart';
import '../fakes/fake_health_sync_service.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets(
    'shows individual Health Connect access states and reviews them',
    (tester) async {
      final service = FakeHealthSyncService(
        authStatus: HealthAuthorizationStatus.granted,
        accessDetailsValue: const HealthDataAccessDetails(
          canInspectIndividualPermissions: true,
          workouts: HealthDataAccessStatus.allowed,
          workoutRoutes: HealthDataAccessStatus.needsAttention,
          heartRate: HealthDataAccessStatus.allowed,
        ),
      );
      final controller = HealthSyncController(
        service: service,
        autoSync: FakeHealthAutoSyncService(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: HealthAccessScreen(controller: controller),
        ),
      );
      await _pumpHealthAccess(tester);

      expect(find.text(l10n.healthAccessWorkouts), findsOneWidget);
      expect(find.text(l10n.healthAccessWorkoutRoutes), findsOneWidget);
      expect(find.text(l10n.healthAccessHeartRate), findsOneWidget);
      expect(find.text(l10n.healthAccessAllowed), findsNWidgets(2));
      expect(find.text(l10n.healthAccessNeedsAttention), findsOneWidget);
      expect(find.text(l10n.healthAccessSystemManagedNotice), findsNothing);

      await tester.tap(find.text(l10n.healthAccessReview));
      await _pumpHealthAccess(tester);

      expect(service.requestAccessCallCount, 1);
    },
  );

  group('Health Connect denial guidance', () {
    Future<_FakeSettings> pumpDenied(
      WidgetTester tester, {
      HealthDataAccessDetails details = const HealthDataAccessDetails(
        canInspectIndividualPermissions: true,
      ),
    }) async {
      final service = FakeHealthSyncService(
        authStatus: HealthAuthorizationStatus.denied,
        accessDetailsValue: details,
      );
      final controller = HealthSyncController(
        service: service,
        autoSync: FakeHealthAutoSyncService(),
      );
      addTearDown(controller.dispose);
      final settings = _FakeSettings();
      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: HealthAccessScreen(
            controller: controller,
            settingsService: settings,
          ),
        ),
      );
      await _pumpHealthAccess(tester);
      await tester.tap(find.text(l10n.healthAccessReview));
      await tester.pumpAndSettle();
      return settings;
    }

    testWidgets('opens the Health Connect permission screen on request', (
      tester,
    ) async {
      final settings = await pumpDenied(tester);

      expect(find.text(l10n.healthAccessBlockedMessage), findsOneWidget);
      await tester.tap(find.text(l10n.healthAccessOpenHealthConnect));
      await tester.pumpAndSettle();

      expect(settings.openCalls, 1);
    });

    testWidgets('does nothing when the guidance is cancelled', (tester) async {
      final settings = await pumpDenied(tester);

      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(settings.openCalls, 0);
    });

    testWidgets('shows no guidance when every category is allowed', (
      tester,
    ) async {
      await pumpDenied(
        tester,
        details: const HealthDataAccessDetails(
          canInspectIndividualPermissions: true,
          workouts: HealthDataAccessStatus.allowed,
          workoutRoutes: HealthDataAccessStatus.allowed,
          heartRate: HealthDataAccessStatus.allowed,
        ),
      );

      expect(find.text(l10n.healthAccessBlockedMessage), findsNothing);
    });

    testWidgets('never calls the Android channel on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final settings = await pumpDenied(tester);

      expect(find.text(l10n.healthAccessBlockedMessage), findsNothing);
      expect(settings.openCalls, 0);
    });
  });

  testWidgets('does not claim individual HealthKit read grants', (
    tester,
  ) async {
    final service = FakeHealthSyncService(
      authStatus: HealthAuthorizationStatus.granted,
    );
    final controller = HealthSyncController(
      service: service,
      autoSync: FakeHealthAutoSyncService(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: HealthAccessScreen(controller: controller),
      ),
    );
    await _pumpHealthAccess(tester);

    expect(find.text(l10n.healthAccessManagedBySystem), findsNWidgets(3));
    expect(find.text(l10n.healthAccessSystemManagedNotice), findsOneWidget);
    expect(find.text(l10n.healthAccessAllowed), findsNothing);

    await tester.tap(find.text(l10n.healthAccessReviewIos));
    await tester.pump();

    expect(find.text(l10n.healthAccessReviewIosInstructions), findsOneWidget);
    expect(service.requestAccessCallCount, 0);
  });

  testWidgets('disconnects health data after confirmation', (tester) async {
    final service = FakeHealthSyncService(
      authStatus: HealthAuthorizationStatus.granted,
      accessDetailsValue: const HealthDataAccessDetails(
        canInspectIndividualPermissions: true,
      ),
    );
    final controller = HealthSyncController(
      service: service,
      autoSync: FakeHealthAutoSyncService(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: HealthAccessScreen(controller: controller),
      ),
    );
    await _pumpHealthAccess(tester);

    await tester.tap(find.text(l10n.healthAccessDisconnect));
    await tester.pumpAndSettle();
    expect(find.text(l10n.healthAccessDisconnectTitle), findsOneWidget);

    await tester.tap(find.text(l10n.healthAccessDisconnect).last);
    await tester.pumpAndSettle();

    expect(service.disconnectCallCount, 1);
  });
}

Future<void> _pumpHealthAccess(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

class _FakeSettings implements HealthConnectSettingsService {
  int openCalls = 0;

  @override
  Future<bool> openPermissions() async {
    openCalls++;
    return true;
  }
}
