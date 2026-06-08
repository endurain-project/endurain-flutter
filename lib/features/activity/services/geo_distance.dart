import 'package:latlong2/latlong.dart';

/// Returns the great-circle distance in meters between two geographic
/// coordinates using the Vincenty formula (via `latlong2`).
///
/// [distance] may be injected in tests to control or stub the calculation.
double geoDistanceMeters(
  double fromLat,
  double fromLng,
  double toLat,
  double toLng, {
  Distance? distance,
}) {
  return (distance ?? const Distance()).as(
    LengthUnit.Meter,
    LatLng(fromLat, fromLng),
    LatLng(toLat, toLng),
  );
}
