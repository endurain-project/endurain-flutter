import 'package:latlong2/latlong.dart';

/// Geometry parsed from a stored GPX document: the ordered track segments and
/// the coordinates within each. Segments preserve pause/resume boundaries so a
/// route can be drawn without connecting across gaps.
class GpxRoute {
  const GpxRoute({required this.segments});

  /// Non-empty track segments, each a list of at least one coordinate.
  final List<List<LatLng>> segments;

  /// All coordinates flattened across every segment, in order.
  List<LatLng> get points => [for (final segment in segments) ...segment];

  /// First recorded coordinate, or `null` when the route has no points.
  LatLng? get start => segments.isEmpty ? null : segments.first.first;

  /// Last recorded coordinate, or `null` when the route has no points.
  LatLng? get end => segments.isEmpty ? null : segments.last.last;
}

/// Parses the coordinate geometry from a GPX 1.1 document produced by
/// `buildGpxDocument`.
///
/// The app only ever renders GPX it authored, so this is a lightweight,
/// dependency-free reader tuned to that known structure (`<trkseg>` blocks of
/// `<trkpt lat=".." lon="..">`) rather than a general-purpose XML parser.
class GpxRouteParser {
  const GpxRouteParser();

  static final RegExp _segmentPattern = RegExp(
    r'<trkseg>(.*?)</trkseg>',
    dotAll: true,
  );

  static final RegExp _trackPointPattern = RegExp(
    r'<trkpt\s+lat="([^"]+)"\s+lon="([^"]+)"',
  );

  /// Returns the parsed [GpxRoute], or `null` when [gpx] contains no valid
  /// track points.
  GpxRoute? parse(String gpx) {
    final segments = <List<LatLng>>[];

    for (final segmentMatch in _segmentPattern.allMatches(gpx)) {
      final points = _pointsIn(segmentMatch.group(1) ?? '');
      if (points.isNotEmpty) {
        segments.add(points);
      }
    }

    // Defensive fallback for documents whose points are not wrapped in a
    // `<trkseg>`: treat every track point as a single segment.
    if (segments.isEmpty) {
      final points = _pointsIn(gpx);
      if (points.isNotEmpty) {
        segments.add(points);
      }
    }

    if (segments.isEmpty) {
      return null;
    }
    return GpxRoute(segments: segments);
  }

  List<LatLng> _pointsIn(String segment) {
    final points = <LatLng>[];
    for (final match in _trackPointPattern.allMatches(segment)) {
      final latitude = double.tryParse(match.group(1)!);
      final longitude = double.tryParse(match.group(2)!);
      if (latitude == null || longitude == null) {
        continue;
      }
      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        continue;
      }
      points.add(LatLng(latitude, longitude));
    }
    return points;
  }
}
