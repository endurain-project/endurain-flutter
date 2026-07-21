import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecordedActivityPoint', () {
    final timestamp = DateTime.utc(2026, 6, 3, 9, 30);

    test('round trips through JSON with all fields', () {
      final point = RecordedActivityPoint(
        timestamp: timestamp,
        latitude: 41.15,
        longitude: -8.61,
        segmentIndex: 3,
        elevationMeters: 120.5,
        horizontalAccuracyMeters: 4.2,
        verticalAccuracyMeters: 2.1,
        headingDegrees: 270,
        headingAccuracyDegrees: 5,
        speedMetersPerSecond: 3.4,
        speedAccuracyMetersPerSecond: 0.5,
        heartRateBpm: 142,
        powerWatts: 250,
        cadenceRpm: 82,
      );

      final restored = RecordedActivityPoint.fromJson(point.toJson());

      expect(restored.timestamp, timestamp);
      expect(restored.latitude, 41.15);
      expect(restored.longitude, -8.61);
      expect(restored.segmentIndex, 3);
      expect(restored.elevationMeters, 120.5);
      expect(restored.horizontalAccuracyMeters, 4.2);
      expect(restored.verticalAccuracyMeters, 2.1);
      expect(restored.headingDegrees, 270);
      expect(restored.headingAccuracyDegrees, 5);
      expect(restored.speedMetersPerSecond, 3.4);
      expect(restored.speedAccuracyMetersPerSecond, 0.5);
      expect(restored.heartRateBpm, 142);
      expect(restored.powerWatts, 250);
      expect(restored.cadenceRpm, 82);
    });

    test('round trips through a JSON line', () {
      final point = RecordedActivityPoint(
        timestamp: timestamp,
        latitude: 1,
        longitude: 2,
        segmentIndex: 0,
      );

      final restored = RecordedActivityPoint.tryParseLine(point.toJsonLine());

      expect(restored, isNotNull);
      expect(restored!.latitude, 1);
      expect(restored.longitude, 2);
    });

    test('omits absent optional fields and defaults them on parse', () {
      final point = RecordedActivityPoint(
        timestamp: timestamp,
        latitude: 1,
        longitude: 2,
        segmentIndex: 1,
      );

      final json = point.toJson();
      expect(json.containsKey('ele'), isFalse);
      expect(json.containsKey('spd'), isFalse);
      expect(json.containsKey('hr'), isFalse);
      expect(json.containsKey('pow'), isFalse);
      expect(json.containsKey('cad'), isFalse);

      final restored = RecordedActivityPoint.fromJson(json);
      expect(restored.elevationMeters, isNull);
      expect(restored.speedMetersPerSecond, isNull);
      expect(restored.heartRateBpm, isNull);
      expect(restored.powerWatts, isNull);
      expect(restored.cadenceRpm, isNull);
      expect(restored.segmentIndex, 1);
    });

    test('converts to an ActivityTrackPoint', () {
      final point = RecordedActivityPoint(
        timestamp: timestamp,
        latitude: 41,
        longitude: -8,
        segmentIndex: 0,
        elevationMeters: 10,
        speedMetersPerSecond: 2,
        headingDegrees: 90,
        horizontalAccuracyMeters: 5,
      );

      final track = point.toTrackPoint();

      expect(track.latitude, 41);
      expect(track.longitude, -8);
      expect(track.timestamp, timestamp);
      expect(track.elevationMeters, 10);
      expect(track.speedMetersPerSecond, 2);
      expect(track.headingDegrees, 90);
      expect(track.horizontalAccuracyMeters, 5);
    });

    test('tryParseLine returns null for blank or malformed lines', () {
      expect(RecordedActivityPoint.tryParseLine(''), isNull);
      expect(RecordedActivityPoint.tryParseLine('   '), isNull);
      expect(RecordedActivityPoint.tryParseLine('not json'), isNull);
      expect(RecordedActivityPoint.tryParseLine('[1,2,3]'), isNull);
      expect(
        RecordedActivityPoint.tryParseLine('{"lat":999,"lon":0,"t":"x"}'),
        isNull,
      );
    });
  });
}
