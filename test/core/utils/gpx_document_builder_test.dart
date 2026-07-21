import 'package:endurain/core/utils/gpx_document_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2025, 6, 1, 9, 0, 0);

  GpxTrackPoint point({
    double lat = 38.7,
    double lon = -9.1,
    double? ele,
    int? hr,
    int? cad,
    int? power,
    int offsetSeconds = 0,
  }) => GpxTrackPoint(
    latitude: lat,
    longitude: lon,
    elevationMeters: ele,
    time: t0.add(Duration(seconds: offsetSeconds)),
    heartRate: hr,
    cadence: cad,
    powerWatts: power,
  );

  group('GpxBounds.fromPoints', () {
    test('returns null for no points', () {
      expect(GpxBounds.fromPoints(const <GpxTrackPoint>[]), isNull);
    });

    test('computes the enclosing box across points', () {
      final bounds = GpxBounds.fromPoints([
        point(lat: 41.1, lon: -8.6),
        point(lat: 41.2, lon: -8.7),
        point(lat: 41.0, lon: -8.5),
      ]);

      expect(bounds, isNotNull);
      expect(bounds!.minLatitude, 41.0);
      expect(bounds.maxLatitude, 41.2);
      expect(bounds.minLongitude, -8.7);
      expect(bounds.maxLongitude, -8.5);
    });
  });

  group('buildGpxDocument', () {
    test('emits the shared document scaffold', () {
      final gpx = buildGpxDocument(
        name: 'run',
        type: 'run',
        metadataTime: t0,
        segments: [
          [point(ele: 20, offsetSeconds: 0)],
        ],
      );

      expect(gpx, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(
        gpx,
        contains(
          '<gpx version="1.1" creator="Endurain mobile app" '
          'xmlns="http://www.topografix.com/GPX/1/1">',
        ),
      );
      expect(gpx, contains('    <name>run</name>'));
      expect(gpx, contains('    <time>2025-06-01T09:00:00.000Z</time>'));
      expect(gpx, contains('    <type>run</type>'));
      expect(gpx, contains('        <ele>20.0</ele>'));
      expect(gpx, endsWith('</gpx>\n'));
    });

    test('omits metadata time and bounds when not provided', () {
      final gpx = buildGpxDocument(
        name: 'walk',
        type: 'walk',
        segments: [
          [point()],
        ],
      );

      expect(gpx, isNot(contains('<bounds')));
      // The metadata time (which follows </link>) is absent; the only <time>
      // present is the deeper-indented track point time inside the trkpt.
      expect(gpx, isNot(contains('</link>\n    <time>')));
    });

    test('writes a bounds element when provided', () {
      final gpx = buildGpxDocument(
        name: 'ride',
        type: 'ride',
        bounds: const GpxBounds(
          minLatitude: 41.1,
          minLongitude: -8.7,
          maxLatitude: 41.2,
          maxLongitude: -8.6,
        ),
        segments: [
          [point()],
        ],
      );

      expect(
        gpx,
        contains(
          '    <bounds minlat="41.1" minlon="-8.7" '
          'maxlat="41.2" maxlon="-8.6" />',
        ),
      );
    });

    test(
      'adds the gpxtpx namespace and hr extension when heart rate present',
      () {
        final gpx = buildGpxDocument(
          name: 'run',
          type: 'run',
          segments: [
            [point(hr: 150), point(hr: 155, offsetSeconds: 5)],
          ],
        );

        expect(gpx, contains('xmlns:gpxtpx='));
        expect(gpx, contains('<gpxtpx:TrackPointExtension>'));
        expect(gpx, contains('<gpxtpx:hr>150</gpxtpx:hr>'));
        expect(gpx, contains('<gpxtpx:hr>155</gpxtpx:hr>'));
      },
    );

    test('omits the gpxtpx namespace when no heart rate present', () {
      final gpx = buildGpxDocument(
        name: 'run',
        type: 'run',
        segments: [
          [point()],
        ],
      );

      expect(gpx, isNot(contains('gpxtpx')));
    });

    test('adds the gpxtpx cadence extension when cadence present', () {
      final gpx = buildGpxDocument(
        name: 'ride',
        type: 'ride',
        segments: [
          [point(cad: 82)],
        ],
      );

      expect(gpx, contains('xmlns:gpxtpx='));
      expect(gpx, contains('<gpxtpx:TrackPointExtension>'));
      expect(gpx, contains('<gpxtpx:cad>82</gpxtpx:cad>'));
    });

    test('adds the ns3 power wrapper extension when power present', () {
      final gpx = buildGpxDocument(
        name: 'ride',
        type: 'ride',
        segments: [
          [point(power: 250)],
        ],
      );

      expect(gpx, contains('xmlns:ns3='));
      expect(gpx, contains('<ns3:wrapper>'));
      expect(gpx, contains('<ns3:power>250</ns3:power>'));
      expect(gpx, contains('</ns3:wrapper>'));
    });

    test('nests hr, cadence, and power in one TrackPointExtension', () {
      final gpx = buildGpxDocument(
        name: 'ride',
        type: 'ride',
        segments: [
          [point(hr: 150, cad: 82, power: 250)],
        ],
      );

      // A single extensions block carries all three sensor values.
      expect('<extensions>'.allMatches(gpx).length, 1);
      expect(gpx, contains('<gpxtpx:hr>150</gpxtpx:hr>'));
      expect(gpx, contains('<gpxtpx:cad>82</gpxtpx:cad>'));
      expect(gpx, contains('<ns3:power>250</ns3:power>'));
    });

    test('omits the ns3 namespace when no power present', () {
      final gpx = buildGpxDocument(
        name: 'run',
        type: 'run',
        segments: [
          [point(hr: 150)],
        ],
      );

      expect(gpx, isNot(contains('ns3')));
    });

    test('emits one trkseg per segment, including empty segments', () {
      final gpx = buildGpxDocument(
        name: 'run',
        type: 'run',
        segments: [
          [point(offsetSeconds: 0)],
          const <GpxTrackPoint>[],
          [point(offsetSeconds: 10)],
        ],
      );

      expect('<trkseg>'.allMatches(gpx).length, 3);
      expect('</trkseg>'.allMatches(gpx).length, 3);
      // The empty middle segment produces an empty trkseg block.
      expect(gpx, contains('    <trkseg>\n    </trkseg>'));
    });

    test('escapes XML metacharacters in the track name', () {
      final gpx = buildGpxDocument(
        name: 'a & b < c',
        type: 'run',
        segments: [
          [point()],
        ],
      );

      expect(gpx, contains('<name>a &amp; b &lt; c</name>'));
    });
  });
}
