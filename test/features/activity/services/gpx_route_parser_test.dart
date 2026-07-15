import 'package:endurain/core/utils/gpx_document_builder.dart';
import 'package:endurain/features/activity/services/gpx_route_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GpxRouteParser', () {
    const parser = GpxRouteParser();

    String buildGpx(List<List<GpxTrackPoint>> segments) {
      return buildGpxDocument(name: 'run', type: 'run', segments: segments);
    }

    GpxTrackPoint point(double lat, double lon) =>
        GpxTrackPoint(latitude: lat, longitude: lon, time: DateTime.utc(2026));

    test('parses track points grouped by segment', () {
      final gpx = buildGpx([
        [point(41.1, -8.6), point(41.2, -8.5)],
        [point(41.3, -8.4)],
      ]);

      final route = parser.parse(gpx)!;

      expect(route.segments, hasLength(2));
      expect(route.segments.first, hasLength(2));
      expect(route.segments.last, hasLength(1));
      expect(route.points, hasLength(3));
      expect(route.start!.latitude, closeTo(41.1, 1e-6));
      expect(route.end!.latitude, closeTo(41.3, 1e-6));
    });

    test('returns null when the document has no track points', () {
      expect(parser.parse(buildGpx([[]])), isNull);
    });

    test('returns null for content that is not GPX', () {
      expect(parser.parse('not a gpx document'), isNull);
    });

    test('skips out-of-range coordinates', () {
      const gpx =
          '<gpx><trk><trkseg>'
          '<trkpt lat="91.0" lon="0.0"></trkpt>'
          '<trkpt lat="10.0" lon="20.0"></trkpt>'
          '</trkseg></trk></gpx>';

      final route = parser.parse(gpx)!;

      expect(route.points, hasLength(1));
      expect(route.points.single.latitude, 10.0);
      expect(route.points.single.longitude, 20.0);
    });
  });
}
