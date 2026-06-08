import 'package:endurain/core/utils/json_parsing.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';

class ActivityGpxBuilder {
  const ActivityGpxBuilder();

  static const String _projectUrl = 'https://codeberg.org/endurain-project';

  String build(ActivityRecordingState state, {String? trackName}) {
    final name = trackName ?? _defaultTrackName(state.activityType);
    final trackType = _trackType(state.activityType);
    final metadataTime = _metadataTime(state);
    final bounds = _boundsFor(state.points);
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<gpx version="1.1" creator="Endurain Mobile" '
        'xmlns="http://www.topografix.com/GPX/1/1">',
      )
      ..writeln('  <metadata>')
      ..writeln('    <name>${_escapeXml(name)}</name>')
      ..writeln('    <link href="$_projectUrl">')
      ..writeln('      <text>Endurain Project</text>')
      ..writeln('    </link>');

    if (metadataTime != null) {
      buffer.writeln('    <time>${_formatTimestamp(metadataTime)}</time>');
    }

    if (bounds != null) {
      buffer.writeln(
        '    <bounds minlat="${_formatCoordinate(bounds.minLatitude)}" '
        'minlon="${_formatCoordinate(bounds.minLongitude)}" '
        'maxlat="${_formatCoordinate(bounds.maxLatitude)}" '
        'maxlon="${_formatCoordinate(bounds.maxLongitude)}" />',
      );
    }

    buffer
      ..writeln('  </metadata>')
      ..writeln('  <trk>')
      ..writeln('    <name>${_escapeXml(name)}</name>')
      ..writeln('    <type>${_escapeXml(trackType)}</type>');

    for (final segment in _segmentsForGpx(state)) {
      buffer.writeln('    <trkseg>');
      for (final point in segment.points) {
        _writeTrackPoint(buffer, point);
      }
      buffer.writeln('    </trkseg>');
    }

    buffer
      ..writeln('  </trk>')
      ..writeln('</gpx>');

    return buffer.toString();
  }

  String _defaultTrackName(ActivityType? activityType) {
    return activityType?.apiValue ?? ActivityType.other.apiValue;
  }

  String _trackType(ActivityType? activityType) {
    return activityType?.apiValue ?? ActivityType.other.apiValue;
  }

  List<ActivityTrackSegment> _segmentsForGpx(ActivityRecordingState state) {
    final segments = state.segments
        .where((segment) => segment.points.isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty) {
      return [ActivityTrackSegment()];
    }
    return segments;
  }

  void _writeTrackPoint(StringBuffer buffer, ActivityTrackPoint point) {
    buffer.writeln(
      '      <trkpt lat="${_formatCoordinate(point.latitude)}" '
      'lon="${_formatCoordinate(point.longitude)}">',
    );

    if (point.elevationMeters != null) {
      buffer.writeln(
        '        <ele>${_formatElevation(point.elevationMeters!)}</ele>',
      );
    }

    buffer.writeln('        <time>${_formatTimestamp(point.timestamp)}</time>');
    buffer.writeln('      </trkpt>');
  }

  String _formatTimestamp(DateTime timestamp) {
    return timestamp.toUtcIso8601();
  }

  DateTime? _metadataTime(ActivityRecordingState state) {
    if (state.startedAt != null) {
      return state.startedAt;
    }
    if (state.points.isEmpty) {
      return null;
    }
    return state.points.first.timestamp;
  }

  _GpxBounds? _boundsFor(List<ActivityTrackPoint> points) {
    if (points.isEmpty) {
      return null;
    }

    var minLatitude = points.first.latitude;
    var minLongitude = points.first.longitude;
    var maxLatitude = points.first.latitude;
    var maxLongitude = points.first.longitude;

    for (final point in points.skip(1)) {
      minLatitude = point.latitude < minLatitude ? point.latitude : minLatitude;
      minLongitude = point.longitude < minLongitude
          ? point.longitude
          : minLongitude;
      maxLatitude = point.latitude > maxLatitude ? point.latitude : maxLatitude;
      maxLongitude = point.longitude > maxLongitude
          ? point.longitude
          : maxLongitude;
    }

    return _GpxBounds(
      minLatitude: minLatitude,
      minLongitude: minLongitude,
      maxLatitude: maxLatitude,
      maxLongitude: maxLongitude,
    );
  }

  String _formatCoordinate(double value) {
    return _formatDecimal(value, maxFractionDigits: 7);
  }

  String _formatElevation(double value) {
    return _formatDecimal(value, maxFractionDigits: 1, minFractionDigits: 1);
  }

  String _formatDecimal(
    double value, {
    required int maxFractionDigits,
    int minFractionDigits = 0,
  }) {
    var text = value.toStringAsFixed(maxFractionDigits);
    if (text.startsWith('-0') && double.parse(text) == 0) {
      text = text.substring(1);
    }
    if (!text.contains('.')) {
      return text;
    }

    while (text.split('.').last.length > minFractionDigits &&
        text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }

    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _GpxBounds {
  const _GpxBounds({
    required this.minLatitude,
    required this.minLongitude,
    required this.maxLatitude,
    required this.maxLongitude,
  });

  final double minLatitude;
  final double minLongitude;
  final double maxLatitude;
  final double maxLongitude;
}
