/// Map configuration constants
class MapConstants {
  // Default location (Lisbon, Portugal)
  static const double defaultLatitude = 38.7223;
  static const double defaultLongitude = -9.1393;

  // Zoom levels
  static const double defaultZoom = 13.0;
  static const double initialLoadZoom = 15.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;

  // User agent
  static const String userAgent = 'com.endurain.endurain';

  // Default tile server URL
  static const String defaultTileServerUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}

/// Location marker visual constants
class LocationMarkerConstants {
  // Marker dimensions
  static const double markerSize = 40.0;
  static const double dotRadius = 8.0; // markerSize / 5
  static const double borderWidth = 3.0;

  // Directional cone dimensions (relative to radius)
  static const double coneWidthMultiplier = 2.5;
  static const double coneHeightMultiplier = 4.5;
  static const double coneArcRadiusMultiplier = 5.0;

  // Colors
  static const int markerBlue = 0xFF4285F4; // Google Blue
  static const double coneOpacity = 0.3;

  // Button padding
  static const double buttonOuterPadding = 16.0;
  static const double buttonInnerPadding = 12.0;
}
