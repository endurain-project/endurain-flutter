import 'package:endurain/core/services/location_settings_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('buildLocationSettings', () {
    const background = BackgroundLocationConfig(
      notificationTitle: 'Recording activity',
      notificationText: 'Tracking your location.',
    );

    test('returns plain foreground settings when background is null', () {
      final settings = buildLocationSettings(platform: TargetPlatform.android);

      expect(settings, isNot(isA<AndroidSettings>()));
      expect(settings, isNot(isA<AppleSettings>()));
      expect(settings.accuracy, LocationAccuracy.high);
      expect(settings.distanceFilter, LocationDistanceFilters.mapMeters);
    });

    test('allows callers to tune distance filter for recording', () {
      final settings = buildLocationSettings(
        distanceFilter: LocationDistanceFilters.recordingMeters,
        platform: TargetPlatform.android,
      );

      expect(settings.distanceFilter, LocationDistanceFilters.recordingMeters);
    });

    test('builds Android foreground service settings for background', () {
      final settings = buildLocationSettings(
        background: background,
        platform: TargetPlatform.android,
      );

      expect(settings, isA<AndroidSettings>());
      final android = settings as AndroidSettings;
      expect(android.forceLocationManager, isFalse);
      expect(android.foregroundNotificationConfig, isNotNull);
      expect(
        android.foregroundNotificationConfig!.notificationTitle,
        'Recording activity',
      );
      expect(
        android.foregroundNotificationConfig!.notificationText,
        'Tracking your location.',
      );
    });

    test('builds Apple background settings for iOS and macOS', () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
        final settings = buildLocationSettings(
          background: background,
          platform: platform,
        );

        expect(settings, isA<AppleSettings>());
        final apple = settings as AppleSettings;
        expect(apple.allowBackgroundLocationUpdates, isTrue);
        expect(apple.showBackgroundLocationIndicator, isTrue);
        expect(apple.pauseLocationUpdatesAutomatically, isFalse);
        expect(apple.activityType, ActivityType.fitness);
      }
    });

    test('falls back to plain settings on unsupported platforms', () {
      final settings = buildLocationSettings(
        background: background,
        platform: TargetPlatform.linux,
      );

      expect(settings, isNot(isA<AndroidSettings>()));
      expect(settings, isNot(isA<AppleSettings>()));
    });
  });
}
