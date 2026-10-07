/// The kind of external-sensor value the recording pipeline can stamp onto an
/// activity. Use this enum inside the activity/recording layer.
///
/// The activity feature consumes sensor readings through this small,
/// self-contained enum rather than depending on the sensors feature's own
/// `SensorMeasurementKind`, so the recording pipeline stays decoupled from the
/// Bluetooth layer. This is a deliberate anti-corruption boundary: the two
/// enums are mapped one-to-one in the composition root by `ActivityModule`
/// (its `_recordedKindFor`), the single place that adapts between the sensors
/// layer and the activity layer. When adding a sensor kind, add it to both
/// enums and extend that mapper.
enum RecordedSensorKind { heartRate, power, cadence }

/// A single external-sensor reading fed into the recording pipeline.
///
/// [value] is the measurement in the unit implied by [kind]: bpm for
/// [RecordedSensorKind.heartRate], watts for [RecordedSensorKind.power], and
/// revolutions or steps per minute for [RecordedSensorKind.cadence]. It is
/// always non-negative.
class RecordedSensorSample {
  const RecordedSensorSample({
    required this.kind,
    required this.timestamp,
    required this.value,
  }) : assert(value >= 0);

  final RecordedSensorKind kind;
  final DateTime timestamp;
  final int value;

  Map<String, Object> toJson() => {
    'schemaVersion': 1,
    'kind': kind.name,
    't': timestamp.toUtc().toIso8601String(),
    'value': value,
  };

  factory RecordedSensorSample.fromJson(Map<Object?, Object?> json) {
    final kind = RecordedSensorKind.values
        .where((kind) => kind.name == json['kind'])
        .firstOrNull;
    final rawTimestamp = json['t'];
    final timestamp = rawTimestamp is String
        ? DateTime.tryParse(rawTimestamp)
        : null;
    final value = json['value'];
    if (json['schemaVersion'] != 1 ||
        kind == null ||
        timestamp == null ||
        value is! int ||
        value < 0) {
      throw const FormatException('Invalid recorded sensor sample.');
    }
    return RecordedSensorSample(
      kind: kind,
      timestamp: timestamp.toUtc(),
      value: value,
    );
  }
}
