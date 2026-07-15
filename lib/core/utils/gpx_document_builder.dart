import 'package:endurain/core/utils/gpx_formatting.dart';

/// A single neutral GPS sample to serialize into a GPX `<trkpt>`.
///
/// Every GPX source (GPS recordings, health-platform workouts) maps its own
/// point type into this shape so [buildGpxDocument] emits an identical document
/// structure regardless of origin.
class GpxTrackPoint {
  const GpxTrackPoint({
    required this.latitude,
    required this.longitude,
    required this.time,
    this.elevationMeters,
    this.heartRate,
  });

  final double latitude;
  final double longitude;
  final DateTime time;
  final double? elevationMeters;
  final int? heartRate;
}

/// Geographic bounding box for a GPX `<bounds>` element.
class GpxBounds {
  const GpxBounds({
    required this.minLatitude,
    required this.minLongitude,
    required this.maxLatitude,
    required this.maxLongitude,
  });

  /// Computes the bounding box enclosing [points], or `null` when [points] is
  /// empty.
  static GpxBounds? fromPoints(Iterable<GpxTrackPoint> points) {
    final iterator = points.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    var minLatitude = iterator.current.latitude;
    var minLongitude = iterator.current.longitude;
    var maxLatitude = minLatitude;
    var maxLongitude = minLongitude;
    while (iterator.moveNext()) {
      final point = iterator.current;
      if (point.latitude < minLatitude) minLatitude = point.latitude;
      if (point.longitude < minLongitude) minLongitude = point.longitude;
      if (point.latitude > maxLatitude) maxLatitude = point.latitude;
      if (point.longitude > maxLongitude) maxLongitude = point.longitude;
    }
    return GpxBounds(
      minLatitude: minLatitude,
      minLongitude: minLongitude,
      maxLatitude: maxLatitude,
      maxLongitude: maxLongitude,
    );
  }

  final double minLatitude;
  final double minLongitude;
  final double maxLatitude;
  final double maxLongitude;
}

const String _gpxtpxNamespace =
    'xmlns:gpxtpx="http://www.garmin.com/xmlschemas/'
    'TrackPointExtension/v1"';

/// Serializes a GPX 1.1 document shared by every track source, guaranteeing an
/// identical structure and byte-for-byte formatting regardless of origin.
///
/// [name] fills the `<metadata><name>` and `<trk><name>` elements; [type] fills
/// `<trk><type>`. [metadataTime] and [bounds] are written only when non-null.
/// Each entry in [segments] becomes a `<trkseg>` (an empty list still emits an
/// empty `<trkseg>`). The Garmin TrackPointExtension namespace and per-point
/// `<gpxtpx:hr>` extensions are emitted only when a point carries a
/// [GpxTrackPoint.heartRate].
String buildGpxDocument({
  required String name,
  required String type,
  DateTime? metadataTime,
  GpxBounds? bounds,
  required List<List<GpxTrackPoint>> segments,
}) {
  final hasHeartRate = segments.any(
    (segment) => segment.any((point) => point.heartRate != null),
  );
  final escapedName = gpxEscapeXml(name);

  final buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..write('<gpx version="1.1" creator="Endurain mobile app" ')
    ..write('xmlns="http://www.topografix.com/GPX/1/1"');
  if (hasHeartRate) {
    buffer.write(' $_gpxtpxNamespace');
  }

  buffer
    ..writeln('>')
    ..writeln('  <metadata>')
    ..writeln('    <name>$escapedName</name>')
    ..writeln('    <link href="$gpxProjectUrl">')
    ..writeln('      <text>Endurain Project</text>')
    ..writeln('    </link>');

  if (metadataTime != null) {
    buffer.writeln('    <time>${gpxFormatTimestamp(metadataTime)}</time>');
  }

  if (bounds != null) {
    buffer.writeln(
      '    <bounds minlat="${gpxFormatCoordinate(bounds.minLatitude)}" '
      'minlon="${gpxFormatCoordinate(bounds.minLongitude)}" '
      'maxlat="${gpxFormatCoordinate(bounds.maxLatitude)}" '
      'maxlon="${gpxFormatCoordinate(bounds.maxLongitude)}" />',
    );
  }

  buffer
    ..writeln('  </metadata>')
    ..writeln('  <trk>')
    ..writeln('    <name>$escapedName</name>')
    ..writeln('    <type>${gpxEscapeXml(type)}</type>');

  for (final segment in segments) {
    buffer.writeln('    <trkseg>');
    for (final point in segment) {
      _writeTrackPoint(buffer, point);
    }
    buffer.writeln('    </trkseg>');
  }

  buffer
    ..writeln('  </trk>')
    ..writeln('</gpx>');

  return buffer.toString();
}

void _writeTrackPoint(StringBuffer buffer, GpxTrackPoint point) {
  buffer.writeln(
    '      <trkpt lat="${gpxFormatCoordinate(point.latitude)}" '
    'lon="${gpxFormatCoordinate(point.longitude)}">',
  );

  final elevation = point.elevationMeters;
  if (elevation != null) {
    buffer.writeln('        <ele>${gpxFormatElevation(elevation)}</ele>');
  }

  buffer.writeln('        <time>${gpxFormatTimestamp(point.time)}</time>');

  final heartRate = point.heartRate;
  if (heartRate != null) {
    buffer
      ..writeln('        <extensions>')
      ..writeln('          <gpxtpx:TrackPointExtension>')
      ..writeln('            <gpxtpx:hr>$heartRate</gpxtpx:hr>')
      ..writeln('          </gpxtpx:TrackPointExtension>')
      ..writeln('        </extensions>');
  }

  buffer.writeln('      </trkpt>');
}
