import 'package:flutter/services.dart';

/// One heart rate reading, covering [start] to [end].
///
/// HealthKit can merge equal consecutive readings into one interval, so a
/// reading is an interval; [start] equals [end] for a single instant.
class HeartRateReading {
  const HeartRateReading({
    required this.start,
    required this.end,
    required this.bpm,
  });

  final DateTime start;
  final DateTime end;
  final double bpm;
}

/// Reads every individual heart rate reading in a time window.
///
/// Exists because the `health` plugin reads HealthKit heart rate with
/// `HKSampleQuery`, which returns a condensed series (one sample holding many
/// readings, common for Apple Workout recordings) as a single summary value.
abstract interface class HeartRateSeriesReader {
  /// Returns the readings that overlap [start]..[end], sorted by start.
  ///
  /// Throws when the native read fails or is not available, so the caller can
  /// fall back to another source.
  Future<List<HeartRateReading>> read({
    required DateTime start,
    required DateTime end,
  });
}

/// iOS implementation backed by `HKQuantitySeriesSampleQuery`
/// (`ios/Runner/Health/HeartRateSeriesChannel.swift`).
class MethodChannelHeartRateSeriesReader implements HeartRateSeriesReader {
  const MethodChannelHeartRateSeriesReader({
    MethodChannel channel = const MethodChannel(_channelName),
  }) : _channel = channel;

  static const String _channelName = 'endurain/health_heart_rate';
  static const String _readMethod = 'readHeartRateSeries';

  final MethodChannel _channel;

  @override
  Future<List<HeartRateReading>> read({
    required DateTime start,
    required DateTime end,
  }) async {
    final raw = await _channel.invokeMethod<Object?>(_readMethod, {
      'startMs': start.millisecondsSinceEpoch,
      'endMs': end.millisecondsSinceEpoch,
    });
    return decodeHeartRateReadings(raw);
  }
}

/// Decodes the channel's flat `[startMs, endMs, bpm, ...]` triples.
///
/// Throws [FormatException] for anything else, so a malformed reply is
/// treated like a failed read rather than as "no heart rate".
List<HeartRateReading> decodeHeartRateReadings(Object? raw) {
  if (raw == null) return const [];
  if (raw is! List || raw.length % 3 != 0) {
    throw const FormatException('Expected flat heart rate reading triples');
  }
  final readings = <HeartRateReading>[];
  for (var i = 0; i < raw.length; i += 3) {
    final startMs = raw[i];
    final endMs = raw[i + 1];
    final bpm = raw[i + 2];
    if (startMs is! num || endMs is! num || bpm is! num) {
      throw const FormatException('Heart rate reading values must be numbers');
    }
    if (!startMs.isFinite || !endMs.isFinite || !bpm.isFinite) continue;
    readings.add(
      HeartRateReading(
        start: DateTime.fromMillisecondsSinceEpoch(
          startMs.round(),
          isUtc: true,
        ),
        end: DateTime.fromMillisecondsSinceEpoch(endMs.round(), isUtc: true),
        bpm: bpm.toDouble(),
      ),
    );
  }
  return readings;
}
