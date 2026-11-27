import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter.dart';
import 'package:endurain/features/activity/services/recording_live_activity_publisher.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_recording_live_activity_adapter.dart';
import '../../../helpers/recording_diagnostics.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final labels = RecordingLiveActivityLabels(
    formatter: ActivityStatsFormatter.of(l10n),
    numberLocale: 'en',
    activityTypes: {
      ActivityType.run: l10n.activityTypeRun,
      ActivityType.ride: l10n.activityTypeRide,
      ActivityType.walk: l10n.activityTypeWalk,
      ActivityType.hike: l10n.activityTypeHike,
      ActivityType.other: l10n.activityTypeOther,
    },
    distance: l10n.activityStatDistance,
    pace: l10n.activityStatPace,
    speed: l10n.activityStatSpeed,
    paused: l10n.activityPausedIndicator,
    autoPaused: l10n.activityAutoPausedIndicator,
  );
  final start = DateTime.utc(2026, 11, 27, 10);

  // 0.01 degrees of latitude in 100 s: about 1.11 km at 11.1 m/s.
  ActivityRecordingState recording(
    ActivityType type, {
    ActivityRecordingStatus status = ActivityRecordingStatus.recording,
    bool isAutoPaused = false,
  }) => ActivityRecordingState(
    status: status,
    activityType: type,
    startedAt: start,
    isAutoPaused: isAutoPaused,
    points: [
      ActivityTrackPoint(latitude: 41.1, longitude: -8, timestamp: start),
      ActivityTrackPoint(
        latitude: 41.11,
        longitude: -8,
        timestamp: start.add(const Duration(seconds: 100)),
      ),
    ],
  );

  late FakeRecordingLiveActivityAdapter adapter;
  late RecordingDiagnostics diagnostics;
  late RecordingLiveActivityPublisher publisher;

  setUp(() {
    adapter = FakeRecordingLiveActivityAdapter();
    diagnostics = RecordingDiagnostics();
    publisher = RecordingLiveActivityPublisher(
      adapter: adapter,
      diagnostics: diagnostics,
    );
  });

  test('sends nothing before the labels are configured', () async {
    publisher.update(recording(ActivityType.run), localSessionId: 'session');
    await pumpEventQueue();

    expect(adapter.updates, isEmpty);
  });

  test('shows a run with its distance and pace', () async {
    publisher
      ..configure(labels)
      ..update(recording(ActivityType.run), localSessionId: 'session');
    await pumpEventQueue();

    final content = adapter.updates.single;
    expect(content.localSessionId, 'session');
    expect(content.title, 'Run');
    expect(content.distanceLabel, 'Distance');
    expect(content.distanceValue, '1.11 km');
    expect(content.speedLabel, 'Pace');
    expect(content.speedValue, labels.formatter.formatPace(11.12));
    expect(content.pausedLabel, 'Paused');
  });

  test('shows speed for any activity other than a run', () async {
    publisher
      ..configure(labels)
      ..update(recording(ActivityType.ride), localSessionId: 'session');
    await pumpEventQueue();

    final content = adapter.updates.single;
    expect(content.title, 'Ride');
    expect(content.speedLabel, 'Speed');
    expect(content.speedValue, '40.0 km/h');
  });

  test('follows the unit preference when the labels change', () async {
    publisher
      ..configure(labels)
      ..update(recording(ActivityType.ride), localSessionId: 'session')
      ..configure(
        RecordingLiveActivityLabels(
          formatter: ActivityStatsFormatter.of(
            l10n,
            system: MeasurementSystem.imperial,
          ),
          numberLocale: labels.numberLocale,
          activityTypes: labels.activityTypes,
          distance: labels.distance,
          pace: labels.pace,
          speed: labels.speed,
          paused: labels.paused,
          autoPaused: labels.autoPaused,
        ),
      );
    await pumpEventQueue();

    expect(adapter.updates.map((content) => content.distanceValue), [
      '1.11 km',
      '3,644 ft',
    ]);
  });

  test('labels an automatic pause as such', () async {
    publisher
      ..configure(labels)
      ..update(
        recording(
          ActivityType.run,
          status: ActivityRecordingStatus.paused,
          isAutoPaused: true,
        ),
        localSessionId: 'session',
      );
    await pumpEventQueue();

    expect(adapter.updates.single.pausedLabel, 'Auto-paused');
  });

  test('sends a state only when the content changed', () async {
    final state = recording(ActivityType.run);
    publisher
      ..configure(labels)
      ..update(state, localSessionId: 'session')
      ..update(
        state.copyWith(elapsedDurationSeconds: 5),
        localSessionId: 'session',
      );
    await pumpEventQueue();

    expect(adapter.updates, hasLength(1));
  });

  test('sends nothing for a session that is not recording or paused', () async {
    publisher.configure(labels);
    for (final status in [
      ActivityRecordingStatus.idle,
      ActivityRecordingStatus.stopping,
      ActivityRecordingStatus.completed,
      ActivityRecordingStatus.failed,
    ]) {
      publisher.update(
        recording(ActivityType.run, status: status),
        localSessionId: 'session',
      );
    }
    publisher.update(recording(ActivityType.run), localSessionId: null);
    await pumpEventQueue();

    expect(adapter.updates, isEmpty);
  });

  test('records a failed update and sends the content again', () async {
    final state = recording(ActivityType.run);
    adapter.failing = true;
    publisher
      ..configure(labels)
      ..update(state, localSessionId: 'session');
    await pumpEventQueue();
    adapter.failing = false;
    publisher.update(state, localSessionId: 'session');
    await pumpEventQueue();

    expect(adapter.updates, hasLength(2));
    expect(diagnostics.events, [
      DiagnosticsEvents.activityLiveActivityUpdateFailed,
    ]);
  });
}
