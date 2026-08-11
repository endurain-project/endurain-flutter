import 'dart:ui';

/// The unit system used to present distances, speeds, paces, and elevations.
///
/// Stored as a user preference and resolved once per screen, then handed to
/// `ActivityStatsFormatter`. Recorded data itself is always persisted in SI
/// base units (metres, metres per second); this only affects presentation, so
/// switching systems never rewrites stored activities or GPX files.
enum MeasurementSystem {
  /// Metres, kilometres, km/h, min/km.
  metric,

  /// Feet, miles, mph, min/mi.
  imperial;

  static MeasurementSystem? fromJson(Object? value) {
    return switch (value) {
      'metric' => MeasurementSystem.metric,
      'imperial' => MeasurementSystem.imperial,
      _ => null,
    };
  }

  String toJson() => name;

  /// The system conventionally used in [locale]'s region.
  ///
  /// Used when the user has expressed no preference, so a first launch in the
  /// US shows miles rather than kilometres. Only the regions that actually use
  /// imperial units for everyday distance are listed:
  /// - `US` (and its territories), `LR`, `MM` use imperial broadly.
  /// - `GB` is officially metric but road and running/cycling distances are
  ///   universally quoted in miles, which is what this app displays.
  ///
  /// A locale with no region subtag falls back to [MeasurementSystem.metric],
  /// the international default.
  static MeasurementSystem forLocale(Locale? locale) {
    final region = locale?.countryCode?.toUpperCase();
    if (region == null) {
      return MeasurementSystem.metric;
    }
    return _imperialRegions.contains(region)
        ? MeasurementSystem.imperial
        : MeasurementSystem.metric;
  }

  static const Set<String> _imperialRegions = {
    'US', // United States
    'AS', // American Samoa
    'GU', // Guam
    'MP', // Northern Mariana Islands
    'PR', // Puerto Rico
    'VI', // U.S. Virgin Islands
    'LR', // Liberia
    'MM', // Myanmar
    'GB', // United Kingdom (miles for road/running distances)
  };
}

/// Unit conversion factors between SI base units and imperial units.
///
/// Kept as exact international definitions so a round-trip through the
/// formatter never drifts.
class UnitConversions {
  const UnitConversions._();

  /// 1 international foot is exactly 0.3048 m.
  static const double metersPerFoot = 0.3048;

  /// 1 international mile is exactly 1609.344 m.
  static const double metersPerMile = 1609.344;

  /// 1 kilometre is exactly 1000 m.
  static const double metersPerKilometer = 1000;

  static double metersToFeet(double meters) => meters / metersPerFoot;

  static double metersToMiles(double meters) => meters / metersPerMile;

  static double metersToKilometers(double meters) =>
      meters / metersPerKilometer;
}
