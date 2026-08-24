import 'package:latlong2/latlong.dart';

/// Vincenty (WGS-84 ellipsoid) calculator matching the geodesic distance the
/// Endurain backend applies to uploaded GPX files.
///
/// Rounding is disabled: `latlong2` rounds every result to whole meters by
/// default, which discards a large fraction of each leg on tracks sampled a few
/// meters apart and skews the accumulated total.
const Distance geodesicDistance = Distance(roundResult: false);

/// Returns the geodesic distance in meters between two geographic coordinates.
///
/// [distance] may be injected in tests to control or stub the calculation.
double geoDistanceMeters(
  double fromLat,
  double fromLng,
  double toLat,
  double toLng, {
  Distance? distance,
}) {
  return (distance ?? geodesicDistance).as(
    LengthUnit.Meter,
    LatLng(fromLat, fromLng),
    LatLng(toLat, toLng),
  );
}
