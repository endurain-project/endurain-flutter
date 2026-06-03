import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActiveActivitySession', () {
    final startedAt = DateTime.utc(2026, 6, 3, 9);

    test('round trips through JSON', () {
      final session = ActiveActivitySession(
        localSessionId: 'session_1',
        activityType: ActivityType.ride,
        status: ActiveActivityStatus.paused,
        startedAt: startedAt,
        resumedAt: startedAt.add(const Duration(minutes: 5)),
        pausedAt: startedAt.add(const Duration(minutes: 10)),
        endedAt: startedAt.add(const Duration(minutes: 20)),
        elapsedDurationSeconds: 600,
        currentSegmentIndex: 2,
      );

      final restored = ActiveActivitySession.fromJson(session.toJson());

      expect(restored.localSessionId, 'session_1');
      expect(restored.activityType, ActivityType.ride);
      expect(restored.status, ActiveActivityStatus.paused);
      expect(restored.startedAt, startedAt);
      expect(restored.resumedAt, session.resumedAt);
      expect(restored.pausedAt, session.pausedAt);
      expect(restored.endedAt, session.endedAt);
      expect(restored.elapsedDurationSeconds, 600);
      expect(restored.currentSegmentIndex, 2);
      expect(restored.schemaVersion, ActiveActivitySession.currentSchemaVersion);
    });

    test('falls back to failed for an unknown status', () {
      final restored = ActiveActivitySession.fromJson({
        'localSessionId': 'session_1',
        'activityType': 'run',
        'status': 'bogus',
        'startedAt': startedAt.toIso8601String(),
      });

      expect(restored.status, ActiveActivityStatus.failed);
    });

    test('defaults optional values and schema version when missing', () {
      final restored = ActiveActivitySession.fromJson({
        'localSessionId': 'session_1',
        'activityType': 'run',
        'status': 'recording',
        'startedAt': startedAt.toIso8601String(),
      });

      expect(restored.resumedAt, isNull);
      expect(restored.pausedAt, isNull);
      expect(restored.endedAt, isNull);
      expect(restored.elapsedDurationSeconds, 0);
      expect(restored.currentSegmentIndex, 0);
      expect(restored.schemaVersion, ActiveActivitySession.currentSchemaVersion);
      expect(restored.isActive, isTrue);
    });

    test('throws when required identifiers are missing', () {
      expect(
        () => ActiveActivitySession.fromJson({
          'activityType': 'run',
          'status': 'recording',
          'startedAt': startedAt.toIso8601String(),
        }),
        throwsFormatException,
      );
      expect(
        () => ActiveActivitySession.fromJson({
          'localSessionId': 'session_1',
          'activityType': 'run',
          'status': 'recording',
        }),
        throwsFormatException,
      );
    });

    test('copyWith can clear nullable fields', () {
      final session = ActiveActivitySession(
        localSessionId: 'session_1',
        activityType: ActivityType.run,
        status: ActiveActivityStatus.paused,
        startedAt: startedAt,
        pausedAt: startedAt,
      );

      final cleared = session.copyWith(pausedAt: null);

      expect(cleared.pausedAt, isNull);
    });
  });
}
