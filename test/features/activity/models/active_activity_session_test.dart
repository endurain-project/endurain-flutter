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
        autoPauseEnabled: true,
        autoPauseDelaySeconds: 15,
        pausedAutomatically: true,
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
      expect(restored.autoPauseEnabled, isTrue);
      expect(restored.autoPauseDelaySeconds, 15);
      expect(restored.pausedAutomatically, isTrue);
      expect(
        restored.schemaVersion,
        ActiveActivitySession.currentSchemaVersion,
      );
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
      expect(
        restored.schemaVersion,
        ActiveActivitySession.currentSchemaVersion,
      );
      expect(restored.isActive, isTrue);
    });

    test('defaults auto-pause fields to disabled for a pre-schema-v3 session '
        '(backwards compatibility)', () {
      final restored = ActiveActivitySession.fromJson({
        'schemaVersion': 2,
        'localSessionId': 'session_1',
        'activityType': 'run',
        'status': 'paused',
        'startedAt': startedAt.toIso8601String(),
      });

      // A session recorded before auto-pause existed must never silently
      // start auto-pausing (or auto-resuming) after an app update.
      expect(restored.autoPauseEnabled, isFalse);
      expect(restored.autoPauseDelaySeconds, 5);
      expect(restored.pausedAutomatically, isFalse);
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

    test('copyWith overrides auto-pause fields independently', () {
      final session = ActiveActivitySession(
        localSessionId: 'session_1',
        activityType: ActivityType.run,
        status: ActiveActivityStatus.recording,
        startedAt: startedAt,
        autoPauseEnabled: true,
        autoPauseDelaySeconds: 10,
      );

      final autoPaused = session.copyWith(
        status: ActiveActivityStatus.paused,
        pausedAutomatically: true,
      );

      expect(autoPaused.pausedAutomatically, isTrue);
      // Untouched fields (including the auto-pause snapshot) are preserved.
      expect(autoPaused.autoPauseEnabled, isTrue);
      expect(autoPaused.autoPauseDelaySeconds, 10);
    });
  });
}
