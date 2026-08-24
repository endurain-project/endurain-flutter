import 'dart:math' as math;

import 'package:endurain/features/activity/models/activity_recording_stats.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/services/geo_distance.dart';
import 'package:latlong2/latlong.dart';

/// Derives activity metrics from recorded track points.
///
/// The aggregation mirrors the Endurain backend's GPX importer so the numbers
/// shown on the device match the ones the server derives from the same upload:
/// speeds come from geodesic position deltas (the GPX carries no speed field),
/// elevation is smoothed before deltas are summed, and zero heart-rate and
/// power samples are treated as sensor dropouts rather than readings.
class ActivityStatsCalculator {
  ActivityStatsCalculator({Distance? distance})
    : _distance = distance ?? geodesicDistance;

  final Distance _distance;

  /// Windows and threshold used by the backend's elevation smoothing pipeline.
  static const int _elevationMedianWindow = 6;
  static const int _elevationAverageWindow = 3;
  static const double _elevationThresholdMeters = 0.1;

  /// Calculates stats from [segments], computing distance only within each
  /// segment so that gaps between pause-and-resume boundaries are not counted.
  ///
  /// Passing an empty list returns zero stats.
  ActivityRecordingStats calculate(List<ActivityTrackSegment> segments) {
    if (segments.isEmpty) {
      return const ActivityRecordingStats(
        distanceMeters: 0,
        durationSeconds: 0,
      );
    }

    var distanceMeters = 0.0;
    var durationSeconds = 0.0;
    double? elevationGainMeters;
    double? currentSpeedMetersPerSecond;
    int? currentHeartRateBpm;
    int? currentPowerWatts;
    int? currentCadenceRpm;
    final speeds = <double>[];
    final heartRates = <int>[];
    final powers = <int>[];
    final cadences = <int>[];

    for (final segment in segments) {
      final points = segment.points;
      final elevations = <double>[];

      for (final point in points) {
        // A zero reading means the sensor dropped out, not a real measurement.
        final bpm = point.heartRateBpm;
        if (bpm != null && bpm != 0) {
          currentHeartRateBpm = bpm;
          heartRates.add(bpm);
        }
        final watts = point.powerWatts;
        if (watts != null && watts != 0) {
          currentPowerWatts = watts;
          powers.add(watts);
        }
        final rpm = point.cadenceRpm;
        if (rpm != null) {
          currentCadenceRpm = rpm;
          cadences.add(rpm);
        }
        final elevation = point.elevationMeters;
        if (elevation != null) {
          elevations.add(elevation);
        }
      }

      for (var index = 1; index < points.length; index += 1) {
        final previous = points[index - 1];
        final current = points[index];
        final pairDistanceMeters = geoDistanceMeters(
          previous.latitude,
          previous.longitude,
          current.latitude,
          current.longitude,
          distance: _distance,
        );
        distanceMeters += pairDistanceMeters;

        final pairSeconds =
            current.timestamp.difference(previous.timestamp).inMicroseconds /
            Duration.microsecondsPerSecond;
        if (pairSeconds > 0) {
          durationSeconds += pairSeconds;
          final pairSpeed = pairDistanceMeters / pairSeconds;
          speeds.add(pairSpeed);
          currentSpeedMetersPerSecond = pairSpeed;
        } else {
          speeds.add(0);
        }
      }

      if (elevations.isNotEmpty) {
        elevationGainMeters =
            (elevationGainMeters ?? 0) + _elevationGainMeters(elevations);
      }
    }

    // The live readout prefers the GPS-reported speed of the last point because
    // it reacts faster; summary metrics stay position-derived so that they
    // agree with what the server computes from the uploaded GPX.
    final lastSegment = segments.last;
    if (lastSegment.points.isNotEmpty) {
      currentSpeedMetersPerSecond =
          lastSegment.points.last.speedMetersPerSecond ??
          currentSpeedMetersPerSecond;
    }

    return ActivityRecordingStats(
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds.round(),
      averageSpeedMetersPerSecond: speeds.isEmpty ? null : _mean(speeds),
      currentSpeedMetersPerSecond: currentSpeedMetersPerSecond,
      maxSpeedMetersPerSecond: speeds.isEmpty ? null : speeds.reduce(math.max),
      elevationGainMeters: elevationGainMeters,
      currentHeartRateBpm: currentHeartRateBpm,
      averageHeartRateBpm: _roundedMean(heartRates),
      currentPowerWatts: currentPowerWatts,
      averagePowerWatts: _roundedMean(powers),
      currentCadenceRpm: currentCadenceRpm,
      averageCadenceRpm: _roundedMean(cadences),
    );
  }

  /// Total ascent over an elevation series.
  ///
  /// Both barometric and GPS altitude jitter by a metre or more between
  /// samples, so summing raw positive deltas inflates the total on flat ground.
  /// A median filter removes spikes, a moving average removes the residual
  /// noise, and only deltas above [_elevationThresholdMeters] are counted.
  static double _elevationGainMeters(List<double> elevations) {
    if (elevations.length < 2) {
      return 0;
    }
    final smoothed = _movingAverage(
      _medianFilter(elevations, _elevationMedianWindow),
      _elevationAverageWindow,
    );
    var gain = 0.0;
    for (var index = 1; index < smoothed.length; index += 1) {
      final delta = smoothed[index] - smoothed[index - 1];
      if (delta > _elevationThresholdMeters) {
        gain += delta;
      }
    }
    return gain;
  }

  static List<double> _medianFilter(List<double> values, int window) {
    if (window < 2) {
      return values;
    }
    return [
      for (var index = 0; index < values.length; index += 1)
        _median(_window(values, index, window)),
    ];
  }

  static List<double> _movingAverage(List<double> values, int window) {
    if (window < 2) {
      return values;
    }
    return [
      for (var index = 0; index < values.length; index += 1)
        _mean(_window(values, index, window)),
    ];
  }

  /// The [window]-wide slice centred on [index], clamped at the series bounds.
  static List<double> _window(List<double> values, int index, int window) {
    final half = window ~/ 2;
    return values.sublist(
      math.max(0, index - half),
      math.min(values.length, index + half + 1),
    );
  }

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static double _mean(Iterable<double> values) {
    return values.reduce((total, value) => total + value) / values.length;
  }

  static int? _roundedMean(List<int> values) {
    if (values.isEmpty) {
      return null;
    }
    return _mean(values.map((value) => value.toDouble())).round();
  }
}
