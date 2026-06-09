import 'dart:async';

import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/controllers/activity_recording_controller.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/services/activity_recording_service.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/features/activity/services/geolocator_activity_location_recorder.dart';
import 'package:endurain/features/map/map_screen.dart';
import 'package:endurain/features/map/map_settings_repository.dart';
import 'package:endurain/features/map/map_state_controller.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive_floating_action_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;

import '../../helpers/fake_location_platform_adapter.dart';
import '../../helpers/fake_preferences_store.dart';
import '../../helpers/in_memory_active_activity_store.dart';
import '../../helpers/widget_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();

  setUp(() {
    debugDefaultTargetPlatformOverride = null;
    PlatformUtils.debugIsApplePlatformOverride = false;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    PlatformUtils.debugResetOverrides();
  });

  group('MapScreen', () {
    testWidgets('renders map controls and toggles location lock', (
      tester,
    ) async {
      final platform = FakeLocationPlatformAdapter(
        currentPosition: testPosition(
          latitude: 41.1579,
          longitude: -8.6291,
          heading: 30,
        ),
      );
      final mapController = await _mapController(platform);
      final activityController = _activityController(platform);

      await tester.pumpWidget(
        _MapTestApp(
          child: MapScreen(
            controller: mapController,
            activityController: activityController,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byTooltip(l10n.myLocation), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.myLocation));
      await tester.pump();

      expect(find.byIcon(Icons.location_searching), findsOneWidget);
      expect(mapController.isLocationLocked, isFalse);

      activityController.dispose();
      mapController.dispose();
      await platform.close();
    });

    testWidgets('renders recorded route after two points', (tester) async {
      final platform = FakeLocationPlatformAdapter(
        currentPosition: testPosition(latitude: 41.1579, longitude: -8.6291),
      );
      final mapController = await _mapController(platform);
      final activityController = _activityController(platform);

      await tester.pumpWidget(
        _MapTestApp(
          child: MapScreen(
            controller: mapController,
            activityController: activityController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PolylineLayer), findsNothing);

      await activityController.start(ActivityType.run);
      platform.addPosition(testPosition(latitude: 41.1, longitude: -8.6));
      await tester.pump();

      expect(find.byType(PolylineLayer), findsNothing);

      platform.addPosition(testPosition(latitude: 41.2, longitude: -8.7));
      await tester.pump();

      expect(find.byType(PolylineLayer), findsOneWidget);
      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(layer.polylines, hasLength(1));
      expect(layer.polylines.single.color, LocationMarkerConstants.activityBlue);

      activityController.dispose();
      mapController.dispose();
      await platform.close();
    });

    testWidgets('renders separate polylines without bridging a paused gap', (
      tester,
    ) async {
      final platform = FakeLocationPlatformAdapter(
        currentPosition: testPosition(latitude: 41.1579, longitude: -8.6291),
      );
      final mapController = await _mapController(platform);
      final activityController = _activityController(platform);

      await tester.pumpWidget(
        _MapTestApp(
          child: MapScreen(
            controller: mapController,
            activityController: activityController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await activityController.start(ActivityType.run);
      platform.addPosition(testPosition(latitude: 41.10, longitude: -8.60));
      await tester.pump();
      platform.addPosition(testPosition(latitude: 41.11, longitude: -8.61));
      await tester.pump();

      unawaited(activityController.pause());
      await tester.pump();
      unawaited(activityController.resume());
      await tester.pump();

      platform.addPosition(testPosition(latitude: 41.30, longitude: -8.80));
      await tester.pump();
      platform.addPosition(testPosition(latitude: 41.31, longitude: -8.81));
      await tester.pump();

      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      // Two separate segments render as two polylines; the paused gap is never
      // bridged with a fake straight line.
      expect(layer.polylines, hasLength(2));
      expect(layer.polylines.first.points, hasLength(2));
      expect(layer.polylines.last.points, hasLength(2));

      activityController.dispose();
      mapController.dispose();
      await platform.close();
    });

    testWidgets('shows the loading indicator while location loads', (
      tester,
    ) async {
      final platform = FakeLocationPlatformAdapter(
        currentPosition: testPosition(latitude: 41.1579, longitude: -8.6291),
        completeCurrentPosition: false,
      );
      final mapController = await _mapController(platform);
      final activityController = _activityController(platform);

      await tester.pumpWidget(
        _MapTestApp(
          child: MapScreen(
            controller: mapController,
            activityController: activityController,
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      platform.completePosition();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);

      activityController.dispose();
      mapController.dispose();
      await platform.close();
    });

    testWidgets('explains iOS background permission before recording', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      PlatformUtils.debugIsApplePlatformOverride = true;
      final platform = FakeLocationPlatformAdapter(
        currentPosition: testPosition(latitude: 41.1579, longitude: -8.6291),
        permission: LocationPermission.whileInUse,
      );
      final mapController = await _mapController(platform);
      final activityController = _activityController(platform);

      await tester.pumpWidget(
        _MapTestApp(
          child: MapScreen(
            controller: mapController,
            activityController: activityController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(l10n.activityStart));
      await tester.pumpAndSettle();

      expect(find.text(l10n.activityBackgroundPermissionTitle), findsOneWidget);
      expect(activityController.state.status, ActivityRecordingStatus.idle);

      await tester.tap(find.text(l10n.activityBackgroundPermissionContinue));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.activityBackgroundPermissionSettingsTitle),
        findsOneWidget,
      );

      await tester.tap(find.text(l10n.activityOpenSettings));
      await tester.pumpAndSettle();

      expect(platform.openAppSettingsCallCount, 1);
      expect(activityController.state.status, ActivityRecordingStatus.idle);

      debugDefaultTargetPlatformOverride = null;
      PlatformUtils.debugIsApplePlatformOverride = false;

      activityController.dispose();
      mapController.dispose();
      await platform.close();
    });

    testWidgets(
      'bottom-aligns the activity overlay with the iOS location button',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        PlatformUtils.debugIsApplePlatformOverride = true;
        final platform = FakeLocationPlatformAdapter(
          currentPosition: testPosition(latitude: 41.1579, longitude: -8.6291),
        );
        final mapController = await _mapController(platform);
        final activityController = _activityController(platform);

        await tester.pumpWidget(
          _MapTestApp(
            child: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(bottom: 34),
                  viewPadding: const EdgeInsets.only(bottom: 34),
                ),
                child: MapScreen(
                  controller: mapController,
                  activityController: activityController,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final surfaceRect = tester.getRect(
          find.byKey(const ValueKey('activityRecordingControlsSurface')),
        );
        final buttonRect = tester.getRect(
          find.byType(AdaptiveFloatingActionButton),
        );

        // With a home-indicator inset the overlay and the floating control must
        // share the same bottom edge instead of only matching when the inset is
        // zero.
        expect(buttonRect.bottom, greaterThan(0));
        expect(surfaceRect.bottom, moreOrLessEquals(buttonRect.bottom));

        debugDefaultTargetPlatformOverride = null;
        PlatformUtils.debugIsApplePlatformOverride = false;

        activityController.dispose();
        mapController.dispose();
        await platform.close();
      },
    );

    testWidgets(
      'bottom-aligns the activity overlay with the Android location button',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        PlatformUtils.debugIsApplePlatformOverride = false;
        final platform = FakeLocationPlatformAdapter(
          currentPosition: testPosition(latitude: 41.1579, longitude: -8.6291),
        );
        final mapController = await _mapController(platform);
        final activityController = _activityController(platform);

        await tester.pumpWidget(
          _MapTestApp(
            child: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(bottom: 24),
                  viewPadding: const EdgeInsets.only(bottom: 24),
                ),
                child: MapScreen(
                  controller: mapController,
                  activityController: activityController,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final surfaceRect = tester.getRect(
          find.byKey(const ValueKey('activityRecordingControlsSurface')),
        );
        final buttonRect = tester.getRect(
          find.byType(AdaptiveFloatingActionButton),
        );

        // The overlay and the floating location button must share the same
        // bottom edge so the controls line up as a single row, matching iOS.
        expect(buttonRect.bottom, greaterThan(0));
        expect(surfaceRect.bottom, moreOrLessEquals(buttonRect.bottom));

        debugDefaultTargetPlatformOverride = null;
        PlatformUtils.debugIsApplePlatformOverride = false;

        activityController.dispose();
        mapController.dispose();
        await platform.close();
      },
    );
  });
}

Future<MapStateController> _mapController(
  FakeLocationPlatformAdapter platform,
) async {
  final prefs = FakePreferencesStore();
  await prefs.write(
    key: 'tile_server_url',
    value: 'https://tiles.example.test/{z}/{x}/{y}.png',
  );

  final controller = MapStateController(
    locationService: LocationService(platformAdapter: platform),
    mapSettingsRepository: MapSettingsRepository(preferences: prefs),
  );
  controller.tileServerUrl = 'https://tiles.example.test/{z}/{x}/{y}.png';
  return controller;
}

ActivityRecordingController _activityController(
  FakeLocationPlatformAdapter platform,
) {
  final locationService = LocationService(platformAdapter: platform);
  return ActivityRecordingController(
    recordingService: ActivityRecordingService(
      locationService: locationService,
      recorder: GeolocatorActivityLocationRecorder(
        store: InMemoryActiveActivityStore(),
        locationService: locationService,
      ),
    ),
    uploadService: ActivityUploadService(
      config: const ActivityUploadConfig(endpoint: '', fieldName: ''),
    ),
    ownsService: true,
  );
}

class _MapTestApp extends TestMaterialApp {
  const _MapTestApp({required super.child});
}
