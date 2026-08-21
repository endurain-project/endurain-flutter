import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/screens/activity_details_screen.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:endurain/features/health/models/health_imported_workout.dart';
import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_sync_state.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/features/health/screens/health_sync_screen.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_health_sync_service.dart';
import '../../../helpers/widget_test_app.dart';

void main() {
  final start = DateTime.utc(2025, 6, 1, 9, 0);
  final end = DateTime.utc(2025, 6, 1, 10, 30);

  HealthWorkout makeWorkout(String id, {bool hasRoute = true}) => HealthWorkout(
    sourceId: id,
    type: HealthWorkoutType.run,
    startedAt: start,
    endedAt: end,
    distanceMeters: 5000,
    route: hasRoute
        ? [HealthRoutePoint(latitude: 38.0, longitude: -9.0, time: start)]
        : const [],
  );

  LocalActivityRecord makeActivity(
    String id, {
    LocalActivityUploadStatus uploadStatus = LocalActivityUploadStatus.pending,
  }) => LocalActivityRecord(
    id: id,
    activityType: ActivityType.run,
    startedAt: start,
    endedAt: end,
    elapsedDurationSeconds: end.difference(start).inSeconds,
    distanceMeters: 5000,
    pointCount: 1,
    gpxFileName: '$id.gpx',
    uploadStatus: uploadStatus,
    createdAt: end,
    updatedAt: end,
  );

  HealthImportedWorkout makeImported(
    String id, {
    LocalActivityRecord? activity,
  }) => HealthImportedWorkout(
    sourceId: 'source-$id',
    localActivityId: id,
    importedAt: end,
    localActivity: activity,
  );

  late FakeHealthSyncService service;
  late HealthSyncController controller;

  HealthSyncController makeController() => HealthSyncController(
    service: service,
    diagnostics: const NoopDiagnosticsRecorder(),
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    controller = makeController();
    PlatformUtils.debugIsApplePlatformOverride = false;
    await tester.pumpWidget(
      TestMaterialApp(child: HealthSyncScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpCupertinoScreen(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double textScaleFactor = 1,
  }) async {
    controller = makeController();
    PlatformUtils.debugIsApplePlatformOverride = true;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          platformBrightness: brightness,
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: AdaptiveApp(
          title: 'Test',
          home: HealthSyncScreen(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(HealthSyncScreen)))!;

  group('HealthSyncScreen', () {
    tearDown(() {
      PlatformUtils.debugResetOverrides();
    });

    testWidgets('shows unsupported message when SDK is unsupported', (
      tester,
    ) async {
      service = FakeHealthSyncService(sdkStatus: HealthSdkStatus.unsupported);
      await pumpScreen(tester);

      final l10n = l10nOf(tester);
      expect(find.text(l10n.healthSyncUnsupported), findsOneWidget);
      addTearDown(controller.dispose);
    });

    testWidgets('shows install prompt when provider install needed', (
      tester,
    ) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.needsProviderInstall,
      );
      await pumpScreen(tester);

      final l10n = l10nOf(tester);
      expect(find.text(l10n.healthSyncInstallProvider), findsOneWidget);
      expect(
        find.text(l10n.healthSyncInstallProviderDescription),
        findsOneWidget,
      );
      addTearDown(controller.dispose);
    });

    testWidgets('tapping install prompts the service to install the provider', (
      tester,
    ) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.needsProviderInstall,
      );
      await pumpScreen(tester);

      final l10n = l10nOf(tester);
      await tester.tap(find.text(l10n.healthSyncInstallProvider));
      await tester.pumpAndSettle();

      expect(service.installHealthConnectCallCount, 1);
      addTearDown(controller.dispose);
    });

    testWidgets('shows authorize button when available but not granted', (
      tester,
    ) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.denied,
      );
      await pumpScreen(tester);

      final l10n = l10nOf(tester);
      expect(find.text(l10n.healthSyncAuthorize), findsOneWidget);
      addTearDown(controller.dispose);
    });

    testWidgets('shows empty state when granted with no workouts', (
      tester,
    ) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
      );
      await pumpScreen(tester);

      final l10n = l10nOf(tester);
      expect(find.text(l10n.healthSyncEmptyState), findsOneWidget);
      expect(find.text(l10n.healthSyncAutoSyncTitle), findsOneWidget);
      addTearDown(controller.dispose);
    });

    testWidgets('toggling a row updates the import-selected label', (
      tester,
    ) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [makeWorkout('w1'), makeWorkout('w2')],
      );
      await pumpScreen(tester);
      final l10n = l10nOf(tester);

      // Workouts load automatically on mount — no manual "find" tap.
      expect(find.byType(AdaptiveCheckboxListTile), findsNWidgets(2));
      expect(find.text(l10n.healthSyncImportSelected(0)), findsOneWidget);

      await tester.tap(find.byType(AdaptiveCheckboxListTile).first);
      await tester.pumpAndSettle();

      expect(find.text(l10n.healthSyncImportSelected(1)), findsOneWidget);
      addTearDown(controller.dispose);
    });

    testWidgets('non-route workouts are not selectable', (tester) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [makeWorkout('w1', hasRoute: false)],
      );
      await pumpScreen(tester);
      final l10n = l10nOf(tester);

      expect(find.text(l10n.healthSyncNoRouteLabel), findsOneWidget);
      final tile = tester.widget<AdaptiveCheckboxListTile>(
        find.byType(AdaptiveCheckboxListTile),
      );
      expect(tile.onChanged, isNull);
      addTearDown(controller.dispose);
    });

    testWidgets('explains why no-route-only workouts cannot be imported', (
      tester,
    ) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [
          makeWorkout('w1', hasRoute: false),
          makeWorkout('w2', hasRoute: false),
        ],
      );
      await pumpScreen(tester);
      final l10n = l10nOf(tester);

      expect(find.text(l10n.healthSyncNoRoutesExplanation), findsOneWidget);
      addTearDown(controller.dispose);
    });

    testWidgets('shows Health app route guidance on iOS', (tester) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [makeWorkout('w1', hasRoute: false)],
        routeConsentDeniedCountValue: 1,
      );
      await pumpScreen(tester);
      final l10n = l10nOf(tester);

      expect(find.text(l10n.healthSyncRouteConsentGuidanceIos), findsOneWidget);
      expect(find.text(l10n.healthSyncRouteConsentGuidance), findsNothing);
      expect(find.text(l10n.healthSyncReviewAccess), findsOneWidget);

      await tester.tap(find.text(l10n.healthSyncReviewAccess));
      await tester.pumpAndSettle();

      expect(find.text(l10n.healthAccessReviewIosInstructions), findsOneWidget);
      expect(service.requestAccessCallCount, 0);
      addTearDown(controller.dispose);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('hides the no-routes banner when a route-bearing workout '
        'exists', (tester) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [makeWorkout('w1'), makeWorkout('w2', hasRoute: false)],
      );
      await pumpScreen(tester);
      final l10n = l10nOf(tester);

      expect(find.text(l10n.healthSyncNoRoutesExplanation), findsNothing);
      addTearDown(controller.dispose);
    });

    testWidgets('unavailable workouts have no selection control', (
      tester,
    ) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [makeWorkout('w1'), makeWorkout('w2', hasRoute: false)],
      );
      await pumpScreen(tester);
      final l10n = l10nOf(tester);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text(l10n.healthSyncNoRouteLabel), findsOneWidget);
      expect(find.text(l10n.healthSyncBadgeNonImportable), findsOneWidget);
      addTearDown(controller.dispose);
    });

    testWidgets('uses accurate running and cycling workout icons', (
      tester,
    ) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [
          makeWorkout('run'),
          HealthWorkout(
            sourceId: 'ride',
            type: HealthWorkoutType.ride,
            startedAt: start,
            endedAt: end,
            route: [
              HealthRoutePoint(latitude: 38.0, longitude: -9.0, time: start),
            ],
          ),
        ],
      );

      await pumpCupertinoScreen(tester);

      expect(find.byIcon(Icons.directions_run), findsOneWidget);
      expect(find.byIcon(Icons.directions_bike), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.flame), findsNothing);
      expect(find.byIcon(CupertinoIcons.bolt), findsNothing);
      addTearDown(controller.dispose);
    });

    testWidgets('import selected invokes the service', (tester) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [makeWorkout('w1')],
      );
      await pumpScreen(tester);
      final l10n = l10nOf(tester);

      await tester.tap(find.byType(AdaptiveCheckboxListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.healthSyncImportSelected(1)));
      await tester.pumpAndSettle();

      expect(service.importWorkoutsCallCount, 1);
      addTearDown(controller.dispose);
    });

    testWidgets('select all feeds the single import action', (tester) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [makeWorkout('w1'), makeWorkout('w2', hasRoute: false)],
      );
      await pumpScreen(tester);
      final l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.healthSyncSelectAll));
      await tester.pumpAndSettle();
      final importAction = find.text(l10n.healthSyncImportSelected(1));
      await tester.ensureVisible(importAction);
      await tester.pumpAndSettle();
      await tester.tap(importAction);
      await tester.pumpAndSettle();

      expect(service.importWorkoutsCallCount, 1);
      expect(service.importAllCallCount, 0);
      addTearDown(controller.dispose);
    });

    testWidgets('changes range and progressively loads older workouts', (
      tester,
    ) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [makeWorkout('w1')],
      )..availableHasMore = true;
      await pumpScreen(tester);
      final l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.healthSyncRange30Days));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.healthSyncRange3Months));
      await tester.pumpAndSettle();

      expect(service.lastRange, const HealthImportRange.last3Months());
      expect(find.text(l10n.healthSyncRange3Months), findsOneWidget);

      await tester.tap(find.text(l10n.activityHistoryLoadMore));
      await tester.pumpAndSettle();

      expect(service.loadMoreAvailableCallCount, 1);
      addTearDown(controller.dispose);
    });

    testWidgets('shows imported upload status and opens activity details', (
      tester,
    ) async {
      PlatformUtils.debugIsApplePlatformOverride = false;
      addTearDown(PlatformUtils.debugResetOverrides);
      final activity = makeActivity(
        'local-1',
        uploadStatus: LocalActivityUploadStatus.uploaded,
      );
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
      )..importedWorkouts = [makeImported('local-1', activity: activity)];
      await pumpScreen(tester);
      final l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.healthSyncViewImported));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          l10n.activityHistoryUploadStatus(l10n.activityUploadStatusUploaded),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.healthSyncRestore), findsNothing);

      final importedTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(importedTile.onTap, isNotNull);
      await tester.tap(find.byType(ListTile));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ActivityDetailsScreen), findsOneWidget);
      addTearDown(controller.dispose);
    });

    testWidgets('restores an imported workout missing locally', (tester) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [makeWorkout('w1')],
      )..importedWorkouts = [makeImported('missing-local')];
      await pumpScreen(tester);
      final l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.healthSyncViewImported));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.healthSyncRestore));
      await tester.pumpAndSettle();

      expect(service.restoreMissingImportCallCount, 1);
      expect(controller.state.selectedView, HealthSyncView.available);
      addTearDown(controller.dispose);
    });

    testWidgets('toggling auto-sync persists via the service', (tester) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
      );
      await pumpScreen(tester);
      final l10n = l10nOf(tester);

      expect(find.text(l10n.healthSyncAutoSyncTitle), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate((w) => w is Switch || w is CupertinoSwitch),
      );
      await tester.pumpAndSettle();

      expect(service.autoSyncOnResumeEnabled, isTrue);
      expect(controller.state.autoSyncOnResume, isTrue);
      addTearDown(controller.dispose);
    });

    testWidgets('pull-to-refresh reloads the importable workouts', (
      tester,
    ) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [makeWorkout('w1')],
      );
      await pumpScreen(tester);

      // One automatic load on mount.
      expect(service.listImportableCallCount, 1);

      await tester.fling(
        find.byType(AdaptiveCheckboxListTile).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(service.listImportableCallCount, 2);
      addTearDown(controller.dispose);
    });

    testWidgets('uses Cupertino selectable rows on iOS', (tester) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [makeWorkout('w1')],
      );
      await pumpCupertinoScreen(tester);

      expect(find.byType(CupertinoListTile), findsWidgets);
      expect(find.byType(CupertinoCheckbox), findsNothing);
      expect(find.byIcon(CupertinoIcons.check_mark), findsNothing);

      await tester.tap(find.byType(AdaptiveCheckboxListTile));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
      addTearDown(controller.dispose);
    });

    testWidgets(
      'renders dark Cupertino controls with readable segment labels',
      (tester) async {
        service = FakeHealthSyncService(
          sdkStatus: HealthSdkStatus.available,
          authStatus: HealthAuthorizationStatus.granted,
          workouts: [makeWorkout('w1')],
        );

        await pumpCupertinoScreen(tester, brightness: Brightness.dark);

        expect(
          find.byType(CupertinoSlidingSegmentedControl<HealthSyncView>),
          findsOneWidget,
        );
        final available = tester.widget<Text>(
          find.text(l10nOf(tester).healthSyncViewAvailable),
        );
        expect(available.style?.color, isNotNull);
        expect(tester.takeException(), isNull);
        addTearDown(controller.dispose);
      },
    );

    testWidgets('supports 200 percent text without layout exceptions', (
      tester,
    ) async {
      service = FakeHealthSyncService(
        sdkStatus: HealthSdkStatus.available,
        authStatus: HealthAuthorizationStatus.granted,
        workouts: [makeWorkout('w1'), makeWorkout('w2', hasRoute: false)],
      );

      await pumpCupertinoScreen(tester, textScaleFactor: 2);

      expect(find.text(l10nOf(tester).healthSyncDateRange), findsOneWidget);
      expect(tester.takeException(), isNull);
      addTearDown(controller.dispose);
    });
  });
}
