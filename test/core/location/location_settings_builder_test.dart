import 'package:endurain/core/location/location_settings_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('buildLocationSettings', () {
    test('returns plain foreground settings', () {
      final settings = buildLocationSettings();

      expect(settings, isNot(isA<AndroidSettings>()));
      expect(settings, isNot(isA<AppleSettings>()));
      expect(settings.accuracy, LocationAccuracy.high);
      expect(settings.distanceFilter, LocationDistanceFilters.mapMeters);
    });

    test('allows callers to tune distance filter', () {
      final settings = buildLocationSettings(
        distanceFilter: LocationDistanceFilters.recordingMeters,
      );

      expect(settings.distanceFilter, LocationDistanceFilters.recordingMeters);
    });
  });
}
