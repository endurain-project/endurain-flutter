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
    r'<trkseg\b[^>]*>(.*?)</trkseg>',
    dotAll: true,
  );

  /// The attribute list of one `<trkpt ...>` start tag. Attributes are read
  /// separately so their order does not matter.
  static final RegExp _trackPointPattern = RegExp(r'<trkpt\b([^>]*)>');

  /// One `name="value"` or `name='value'` attribute.
  static final RegExp _attributePattern = RegExp(
    r'''([A-Za-z_:][\w:.-]*)\s*=\s*(?:"([^"]*)"|'([^']*)')''',
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
      String? latText;
      String? lonText;
      for (final attribute in _attributePattern.allMatches(
        match.group(1) ?? '',
      )) {
        final value = attribute.group(2) ?? attribute.group(3) ?? '';
        switch (attribute.group(1)) {
          case 'lat':
            latText = value;
          case 'lon':
            lonText = value;
        }
      }
      final latitude = latText == null ? null : double.tryParse(latText.trim());
      final longitude = lonText == null
          ? null
          : double.tryParse(lonText.trim());
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
