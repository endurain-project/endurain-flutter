import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/recorded_sensor_sample.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/recording_sensor_session.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSensorRecorder implements ActivitySensorRecorder {
  final appended = <RecordedSensorSample>[];
  List<RecordedSensorSample> stored = [];
  bool failAppend = false;

  @override
  Future<void> appendSensorSample({
    required String localSessionId,
    required RecordedSensorSample sample,
  }) async {
    if (failAppend) {
      throw StateError('disk full');
    }
    appended.add(sample);
  }

  @override
  Future<List<RecordedSensorSample>> drainSensorSamples({
    required String localSessionId,
  }) async => stored;
}

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);
  RecordedSensorSample hr(int offsetSeconds, int bpm) => RecordedSensorSample(
    kind: RecordedSensorKind.heartRate,
    timestamp: t0.add(Duration(seconds: offsetSeconds)),
    value: bpm,
  );
  final point = ActivityTrackPoint(latitude: 1, longitude: 1, timestamp: t0);

  late _FakeSensorRecorder recorder;
  late String? activeSessionId;
  late bool recording;
  late bool disposed;
  late List<Object> failures;
  late List<RecordedSensorSample> recorded;
  late RecordingSensorSession session;

  setUp(() {
    recorder = _FakeSensorRecorder();
    activeSessionId = 's1';
    recording = true;
    disposed = false;
    failures = [];
    recorded = [];
    session = RecordingSensorSession(
      recorder: recorder,
      freshness: const Duration(seconds: 5),
      activeSessionId: () => activeSessionId,
      isRecording: () => recording,
      isDisposed: () => disposed,
      onWriteFailed: (error, _) => failures.add(error),
      onSampleRecorded: recorded.add,
    );
  });

  test('persists and buffers readings while capturing', () async {
    session.startCapture('s1');
    session.onReading(hr(0, 140));

    expect(await session.flush(), isTrue);
    expect(recorder.appended, hasLength(1));
    expect(recorded, hasLength(1));
    expect(session.overlay(point, t0).heartRateBpm, 140);
  });

  test(
    'ignores readings before capture starts or while not recording',
    () async {
      session.onReading(hr(0, 140));
      session.startCapture('s1');
      recording = false;
      session.onReading(hr(1, 141));

      await session.flush();
      expect(recorder.appended, isEmpty);
      expect(session.overlay(point, t0).heartRateBpm, isNull);
    },
  );

  test('stopCapture stops accepting readings', () async {
    session.startCapture('s1');
    session.stopCapture();
    session.onReading(hr(0, 140));

    await session.flush();
    expect(recorder.appended, isEmpty);
  });

  test('drops a reading whose session is no longer active', () async {
    session.startCapture('s1');
    session.onReading(hr(0, 140));
    activeSessionId = 's2';

    await session.flush();
    expect(recorder.appended, isEmpty);
    expect(recorded, isEmpty);
  });

  test('a write failure is reported once and flush returns false', () async {
    session.startCapture('s1');
    recorder.failAppend = true;
    session.onReading(hr(0, 140));
    session.onReading(hr(1, 141));

    expect(await session.flush(), isFalse);
    expect(failures, hasLength(1));
    expect(recorded, isEmpty);
  });

  test('reset clears the failure flag and buffers', () async {
    session.startCapture('s1');
    recorder.failAppend = true;
    session.onReading(hr(0, 140));
    await session.flush();

    session.reset();
    recorder.failAppend = false;
    session.startCapture('s1');
    session.onReading(hr(1, 141));

    expect(await session.flush(), isTrue);
    // The pre-reset 140 reading sat exactly at t0; only 141 remains.
    expect(session.overlay(point, t0).heartRateBpm, 141);
  });

  test('flush returns false once disposed', () async {
    disposed = true;
    expect(await session.flush(), isFalse);
  });

  test('restore reloads persisted samples in time order', () async {
    recorder.stored = [hr(10, 150), hr(0, 140)];
    await session.restore();

    expect(session.overlay(point, t0).heartRateBpm, 140);
    expect(
      session.overlay(point, t0.add(const Duration(seconds: 10))).heartRateBpm,
      150,
    );
  });

  test('restore is a no-op without a recorder or active session', () async {
    activeSessionId = null;
    recorder.stored = [hr(0, 140)];
    await session.restore();
    expect(session.overlay(point, t0).heartRateBpm, isNull);
  });

  test('overlay ignores readings outside the freshness window', () async {
    session.startCapture('s1');
    session.onReading(hr(0, 140));
    await session.flush();

    expect(
      session.overlay(point, t0.add(const Duration(seconds: 60))).heartRateBpm,
      isNull,
    );
  });
}
