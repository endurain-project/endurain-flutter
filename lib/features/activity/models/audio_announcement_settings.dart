import 'dart:convert';

import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/activity/models/activity_type.dart';

/// Whether an [AudioAnnouncementInterval] fires on distance or elapsed time.
enum AudioAnnouncementIntervalUnit {
  distance('distance'),
  time('time');

  const AudioAnnouncementIntervalUnit(this.apiValue);

  final String apiValue;

  static AudioAnnouncementIntervalUnit fromJson(Object? value) {
    return switch (value) {
      'time' => AudioAnnouncementIntervalUnit.time,
      _ => AudioAnnouncementIntervalUnit.distance,
    };
  }

  String toJson() => apiValue;
}

/// How often a spoken progress update fires for one activity type.
///
/// Only the field matching [unit] is meaningful; the other is retained so
/// switching the segmented control in settings does not lose the previously
/// configured value. Both fields are clamped to a sane, non-zero range so a
/// corrupt or hand-edited preference can never produce a zero or negative
/// interval, which would otherwise announce on every single location fix.
class AudioAnnouncementInterval {
  const AudioAnnouncementInterval({
    this.enabled = true,
    this.unit = AudioAnnouncementIntervalUnit.distance,
    this.distanceMeters = defaultDistanceMeters,
    this.timeSeconds = defaultTimeSeconds,
  });

  factory AudioAnnouncementInterval.defaultsFor(
    ActivityType type, {
    MeasurementSystem measurementSystem = MeasurementSystem.metric,
  }) {
    final distanceUnits = type == ActivityType.ride ? 5 : 1;
    final metersPerUnit = measurementSystem == MeasurementSystem.imperial
        ? UnitConversions.metersPerMile
        : UnitConversions.metersPerKilometer;
    return AudioAnnouncementInterval(
      enabled: type != ActivityType.other,
      distanceMeters: distanceUnits * metersPerUnit,
    );
  }

  /// One kilometre — a sensible default for distance-based announcements.
  static const double defaultDistanceMeters = 1000;

  /// Five minutes — a sensible default for time-based announcements.
  static const int defaultTimeSeconds = 300;

  static const double minDistanceMeters = 100;
  static const double maxDistanceMeters = 50000;
  static const int minTimeSeconds = 60;
  static const int maxTimeSeconds = 3600;

  final bool enabled;
  final AudioAnnouncementIntervalUnit unit;
  final double distanceMeters;
  final int timeSeconds;

  /// The interval value in the unit that actually applies right now (metres
  /// for [AudioAnnouncementIntervalUnit.distance], seconds for
  /// [AudioAnnouncementIntervalUnit.time]).
  double get activeValue => unit == AudioAnnouncementIntervalUnit.distance
      ? distanceMeters
      : timeSeconds.toDouble();

  AudioAnnouncementInterval copyWith({
    bool? enabled,
    AudioAnnouncementIntervalUnit? unit,
    double? distanceMeters,
    int? timeSeconds,
  }) {
    return AudioAnnouncementInterval(
      enabled: enabled ?? this.enabled,
      unit: unit ?? this.unit,
      distanceMeters: (distanceMeters ?? this.distanceMeters).clamp(
        minDistanceMeters,
        maxDistanceMeters,
      ),
      timeSeconds: (timeSeconds ?? this.timeSeconds).clamp(
        minTimeSeconds,
        maxTimeSeconds,
      ),
    );
  }

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'unit': unit.toJson(),
    'distanceMeters': distanceMeters,
    'timeSeconds': timeSeconds,
  };

  factory AudioAnnouncementInterval.fromJson(Object? json) {
    if (json is! Map) {
      return const AudioAnnouncementInterval();
    }
    final distance = json['distanceMeters'];
    final time = json['timeSeconds'];
    return AudioAnnouncementInterval(
      enabled: json['enabled'] != false,
      unit: AudioAnnouncementIntervalUnit.fromJson(json['unit']),
      distanceMeters:
          (distance is num ? distance.toDouble() : defaultDistanceMeters).clamp(
            minDistanceMeters,
            maxDistanceMeters,
          ),
      timeSeconds: (time is num ? time.toInt() : defaultTimeSeconds).clamp(
        minTimeSeconds,
        maxTimeSeconds,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AudioAnnouncementInterval &&
        other.enabled == enabled &&
        other.unit == unit &&
        other.distanceMeters == distanceMeters &&
        other.timeSeconds == timeSeconds;
  }

  @override
  int get hashCode => Object.hash(enabled, unit, distanceMeters, timeSeconds);
}

/// Persisted audio-announcement preferences: a master on/off switch, whether
/// other audio should duck while speaking, and a per-[ActivityType] interval.
///
/// Immutable: every mutation returns a new instance, matching the other
/// settings models in this app (see `LocalActivityRecord.copyWith`).
class AudioAnnouncementSettings {
  const AudioAnnouncementSettings({
    this.masterEnabled = false,
    this.duckOtherAudio = true,
    Map<ActivityType, AudioAnnouncementInterval> intervalsByActivityType =
        const {},
  }) : _intervalsByActivityType = intervalsByActivityType;

  final bool masterEnabled;
  final bool duckOtherAudio;
  final Map<ActivityType, AudioAnnouncementInterval> _intervalsByActivityType;

  /// Defaults: globally disabled, ducking enabled, and activity-specific
  /// intervals supplied lazily by [intervalFor].
  factory AudioAnnouncementSettings.defaults() =>
      const AudioAnnouncementSettings();

  /// The configured interval for [type], or the default interval when the
  /// user has never customized it.
  AudioAnnouncementInterval intervalFor(
    ActivityType type, {
    MeasurementSystem measurementSystem = MeasurementSystem.metric,
  }) {
    return _intervalsByActivityType[type] ??
        AudioAnnouncementInterval.defaultsFor(
          type,
          measurementSystem: measurementSystem,
        );
  }

  AudioAnnouncementSettings copyWith({
    bool? masterEnabled,
    bool? duckOtherAudio,
  }) {
    return AudioAnnouncementSettings(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      duckOtherAudio: duckOtherAudio ?? this.duckOtherAudio,
      intervalsByActivityType: _intervalsByActivityType,
    );
  }

  /// Returns a copy with [type]'s interval replaced by [interval].
  AudioAnnouncementSettings withInterval(
    ActivityType type,
    AudioAnnouncementInterval interval,
  ) {
    return AudioAnnouncementSettings(
      masterEnabled: masterEnabled,
      duckOtherAudio: duckOtherAudio,
      intervalsByActivityType: {..._intervalsByActivityType, type: interval},
    );
  }

  String toJsonString() {
    return jsonEncode({
      'masterEnabled': masterEnabled,
      'duckOtherAudio': duckOtherAudio,
      'intervals': {
        for (final entry in _intervalsByActivityType.entries)
          entry.key.apiValue: entry.value.toJson(),
      },
    });
  }

  /// Parses a value previously produced by [toJsonString]. Falls back to
  /// [AudioAnnouncementSettings.defaults] for `null`, empty, or malformed
  /// input so a corrupt preference never blocks recording.
  factory AudioAnnouncementSettings.fromJsonString(String? source) {
    if (source == null || source.isEmpty) {
      return AudioAnnouncementSettings.defaults();
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        return AudioAnnouncementSettings.defaults();
      }
      final intervals = <ActivityType, AudioAnnouncementInterval>{};
      final rawIntervals = decoded['intervals'];
      if (rawIntervals is Map) {
        for (final entry in rawIntervals.entries) {
          final type = ActivityType.fromApiValue(entry.key as String?);
          intervals[type] = AudioAnnouncementInterval.fromJson(entry.value);
        }
      }
      return AudioAnnouncementSettings(
        masterEnabled: decoded['masterEnabled'] == true,
        duckOtherAudio: decoded['duckOtherAudio'] != false,
        intervalsByActivityType: intervals,
      );
    } on FormatException {
      return AudioAnnouncementSettings.defaults();
    }
  }
}
