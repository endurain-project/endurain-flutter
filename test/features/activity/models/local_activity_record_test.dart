import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalActivityRecord', () {
    test('parses known and unknown upload statuses safely', () {
      expect(
        LocalActivityUploadStatus.fromJson('pending'),
        LocalActivityUploadStatus.pending,
      );
      expect(
        LocalActivityUploadStatus.fromJson('uploaded'),
        LocalActivityUploadStatus.uploaded,
      );
      expect(
        LocalActivityUploadStatus.fromJson('future_status'),
        LocalActivityUploadStatus.failed,
      );
    });

    test('round trips coordinate-free metadata through json', () {
      final record = _record(
        uploadStatus: LocalActivityUploadStatus.failed,
        lastUploadErrorCode: AppErrorCode.activityUploadFailed,
      );

      final json = record.toJson();
      final parsed = LocalActivityRecord.fromJson(json);

      expect(parsed.id, record.id);
      expect(parsed.activityType, ActivityType.run);
      expect(parsed.startedAt, record.startedAt);
      expect(parsed.endedAt, record.endedAt);
      expect(parsed.elapsedDurationSeconds, 120);
      expect(parsed.distanceMeters, 500);
      expect(parsed.averageSpeedMetersPerSecond, 4.16);
      expect(parsed.pointCount, 3);
      expect(parsed.gpxFileName, 'activity_1.gpx');
      expect(parsed.uploadStatus, LocalActivityUploadStatus.failed);
      expect(parsed.lastUploadErrorCode, AppErrorCode.activityUploadFailed);
      expect(parsed.autoRetryEligible, isTrue);
      expect(json.containsKey('points'), isFalse);
      expect(json.containsKey('coordinates'), isFalse);
    });

    test('handles missing optional fields', () {
      final parsed = LocalActivityRecord.fromJson({
        'id': 'activity_1',
        'activityType': 'run',
        'startedAt': '2026-06-02T10:00:00Z',
        'endedAt': '2026-06-02T10:02:00Z',
        'elapsedDurationSeconds': 120,
        'distanceMeters': 500,
        'pointCount': 3,
        'gpxFileName': 'activity_1.gpx',
        'uploadStatus': 'uploaded',
        'createdAt': '2026-06-02T10:02:01Z',
        'updatedAt': '2026-06-02T10:02:02Z',
      });

      expect(parsed.averageSpeedMetersPerSecond, isNull);
      expect(parsed.maxSpeedMetersPerSecond, isNull);
      expect(parsed.elevationGainMeters, isNull);
      expect(parsed.uploadedAt, isNull);
      expect(parsed.lastUploadAttemptAt, isNull);
      expect(parsed.lastUploadErrorCode, isNull);
      expect(parsed.autoRetryEligible, isTrue);
    });

    test('round trips automatic retry eligibility', () {
      final parsed = LocalActivityRecord.fromJson(
        _record().copyWith(autoRetryEligible: false).toJson(),
      );

      expect(parsed.autoRetryEligible, isFalse);
    });

    test('round trips max speed and elevation gain', () {
      final parsed = LocalActivityRecord.fromJson(
        _record()
            .copyWith(maxSpeedMetersPerSecond: 7.5, elevationGainMeters: 312.0)
            .toJson(),
      );

      expect(parsed.maxSpeedMetersPerSecond, 7.5);
      expect(parsed.elevationGainMeters, 312.0);
    });
  });
}

LocalActivityRecord _record({
  LocalActivityUploadStatus uploadStatus = LocalActivityUploadStatus.pending,
  AppErrorCode? lastUploadErrorCode,
}) {
  return LocalActivityRecord(
    id: 'activity_1',
    activityType: ActivityType.run,
    startedAt: DateTime.utc(2026, 6, 2, 10),
    endedAt: DateTime.utc(2026, 6, 2, 10, 2),
    elapsedDurationSeconds: 120,
    distanceMeters: 500,
    averageSpeedMetersPerSecond: 4.16,
    pointCount: 3,
    gpxFileName: 'activity_1.gpx',
    uploadStatus: uploadStatus,
    createdAt: DateTime.utc(2026, 6, 2, 10, 2, 1),
    updatedAt: DateTime.utc(2026, 6, 2, 10, 2, 2),
    lastUploadErrorCode: lastUploadErrorCode,
  );
}
