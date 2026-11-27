import 'package:geolocator/geolocator.dart';

class LocationDistanceFilters {
  const LocationDistanceFilters._();

  static const int currentPositionMeters = 10;
  static const int mapMeters = 5;
  static const int recordingMeters = 3;
}

/// Localized text shown in the native recorder's persistent notification
/// while location tracking runs in the background.
///
/// The strings are supplied by the UI layer so they stay localized; core
/// services never reach into the widget tree for translations.
class BackgroundLocationConfig {
  const BackgroundLocationConfig({
    required this.notificationTitle,
    required this.notificationText,
  });

  final String notificationTitle;
  final String notificationText;
}

/// Builds foreground [LocationSettings] for the map position stream.
LocationSettings buildLocationSettings({
  LocationAccuracy accuracy = LocationAccuracy.high,
  int distanceFilter = LocationDistanceFilters.mapMeters,
}) {
  return LocationSettings(accuracy: accuracy, distanceFilter: distanceFilter);
}
