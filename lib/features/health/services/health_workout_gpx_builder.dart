import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/gpx_formatting.dart';
import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_workout.dart';

/// Converts a [HealthWorkout] into a GPX 1.1 string for upload to the
/// Endurain server.
///
/// The output includes standard track-point extensions for heart rate
/// (`gpxtpx:TrackPointExtension / gpxtpx:hr`) when the route points carry
/// heart rate data.
///
/// Throws [AppException] with [AppErrorCode.healthGpxBuildFailed] if the
/// workout has no route points (caller should guard against this with
/// [HealthWorkout.hasRoute] before calling).
class HealthWorkoutGpxBuilder {
  const HealthWorkoutGpxBuilder();

  static const String _gpxtpxNs =
      'xmlns:gpxtpx="http://www.garmin.com/xmlschemas/'
      'TrackPointExtension/v1"';

  /// Builds a GPX 1.1 document from [workout].
  ///
  /// Throws [AppException] with [AppErrorCode.healthGpxBuildFailed] if
  /// [HealthWorkout.hasRoute] is false.
  String build(HealthWorkout workout) {
    if (!workout.hasRoute) {
      throw AppException(
        AppErrorCode.healthGpxBuildFailed,
        details: 'workout has no GPS route: ${workout.sourceId}',
      );
    }

    try {
      final trackType = workout.type.toActivityType().apiValue;
      final metadataTime = gpxFormatTimestamp(workout.startedAt);
      final hasHr = workout.route.any((pt) => pt.heartRate != null);

      final buffer = StringBuffer()
        ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
        ..write('<gpx version="1.1" creator="Endurain Mobile" ')
        ..write('xmlns="http://www.topografix.com/GPX/1/1"');

      if (hasHr) {
        buffer.write(' $_gpxtpxNs');
      }

      buffer
        ..writeln('>')
        ..writeln('  <metadata>')
        ..writeln('    <name>${gpxEscapeXml(trackType)}</name>')
        ..writeln('    <link href="$gpxProjectUrl">')
        ..writeln('      <text>Endurain Project</text>')
        ..writeln('    </link>')
        ..writeln('    <time>$metadataTime</time>')
        ..writeln('  </metadata>')
        ..writeln('  <trk>')
        ..writeln('    <name>${gpxEscapeXml(trackType)}</name>')
        ..writeln('    <type>${gpxEscapeXml(trackType)}</type>')
        ..writeln('    <trkseg>');

      for (final point in workout.route) {
        _writeTrackPoint(buffer, point, hasHr: hasHr);
      }

      buffer
        ..writeln('    </trkseg>')
        ..writeln('  </trk>')
        ..writeln('</gpx>');

      return buffer.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(AppErrorCode.healthGpxBuildFailed, cause: e);
    }
  }

  void _writeTrackPoint(
    StringBuffer buffer,
    HealthRoutePoint point, {
    required bool hasHr,
  }) {
    buffer.writeln(
      '      <trkpt lat="${gpxFormatCoordinate(point.latitude)}" '
      'lon="${gpxFormatCoordinate(point.longitude)}">',
    );

    if (point.elevation != null) {
      buffer.writeln(
        '        <ele>${gpxFormatElevation(point.elevation!)}</ele>',
      );
    }

    buffer.writeln('        <time>${gpxFormatTimestamp(point.time)}</time>');

    if (hasHr && point.heartRate != null) {
      buffer
        ..writeln('        <extensions>')
        ..writeln('          <gpxtpx:TrackPointExtension>')
        ..writeln('            <gpxtpx:hr>${point.heartRate}</gpxtpx:hr>')
        ..writeln('          </gpxtpx:TrackPointExtension>')
        ..writeln('        </extensions>');
    }

    buffer.writeln('      </trkpt>');
  }
}
