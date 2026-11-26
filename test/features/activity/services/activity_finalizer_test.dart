import 'dart:io';

import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_finalizer.dart';
import 'package:endurain/features/activity/services/local_activity_summary_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sqlite_local_activity_repository.dart';

void main() {
  late Directory directory;
  late LocalActivityRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('endurain_finalizer_');
    repository = createTestLocalActivityRepository(directory);
  });

  tearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });

  ActivityRecordingState completedState(int pointCount) {
    final start = DateTime.utc(2026, 6, 3, 9);
    return ActivityRecordingState(
      status: ActivityRecordingStatus.completed,
      activityType: ActivityType.run,
      startedAt: start,
      endedAt: start.add(Duration(seconds: pointCount)),
      elapsedDurationSeconds: pointCount,
      segments: [
        ActivityTrackSegment(
          points: [
            for (var i = 0; i < pointCount; i++)
              ActivityTrackPoint(
                latitude: 41 + i * 0.0001,
                longitude: -8,
                timestamp: start.add(Duration(seconds: i)),
              ),
          ],
        ),
      ],
    );
  }

  ActivityFinalizer finalizer({int isolateThresholdPoints = 2000}) =>
      ActivityFinalizer(
        repository: repository,
        summaryBuilder: LocalActivitySummaryBuilder(),
        now: () => DateTime.utc(2026, 6, 3, 10),
        isolateThresholdPoints: isolateThresholdPoints,
      );

  test('finalize stores the GPX and a pending record', () async {
    final record = await finalizer().finalize(
      state: completedState(5),
      id: 'a1',
      connectionOrigin: 'https://example.test',
      connectionProfileId: 'p1',
    );

    expect(record.uploadStatus, LocalActivityUploadStatus.pending);
    expect(record.pointCount, 5);
    expect(record.connectionOrigin, 'https://example.test');
    expect(record.createdAt, DateTime.utc(2026, 6, 3, 10));
    expect(await repository.get('a1'), isNotNull);
  });

  test('builds identical GPX inline and on a worker isolate', () async {
    final state = completedState(30);

    final inline = await finalizer().buildGpx(state);
    final isolated = await finalizer(isolateThresholdPoints: 1).buildGpx(state);

    expect(isolated, inline);
    expect(inline, contains('<trkpt'));
  });
}
