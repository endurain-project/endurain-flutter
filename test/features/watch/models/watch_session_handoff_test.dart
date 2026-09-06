import 'package:endurain/features/watch/models/watch_session_handoff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, Object?> validPayload() => {
    'version': WatchSessionHandoff.currentPayloadVersion,
    'source': 'appleWatch',
    'complete': true,
    'session': {
      'localSessionId': 'watch_session_1',
      'activityType': 'run',
      'status': 'completed',
      'startedAt': '2026-06-03T09:00:00.000Z',
      'endedAt': '2026-06-03T09:30:00.000Z',
      'elapsedDurationSeconds': 1800,
    },
    'points': [
      {'t': '2026-06-03T09:00:00.000Z', 'lat': 41.0, 'lon': -8.0, 'seg': 0},
      {'t': '2026-06-03T09:00:05.000Z', 'lat': 41.1, 'lon': -8.1, 'seg': 0},
    ],
  };

  group('WatchSessionHandoff.fromJson', () {
    test('parses a complete payload', () {
      final handoff = WatchSessionHandoff.fromJson(validPayload());

      expect(handoff.source, WatchSource.appleWatch);
      expect(handoff.isComplete, isTrue);
      expect(handoff.sessionId, 'watch_session_1');
      expect(handoff.points, hasLength(2));
      expect(handoff.session.elapsedDurationSeconds, 1800);
    });

    test('rejects an unsupported payload version', () {
      final payload = validPayload()..['version'] = 99;

      expect(
        () => WatchSessionHandoff.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a missing payload version', () {
      final payload = validPayload()..remove('version');

      expect(
        () => WatchSessionHandoff.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an unknown source', () {
      final payload = validPayload()..['source'] = 'tizen';

      expect(
        () => WatchSessionHandoff.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a missing session envelope', () {
      final payload = validPayload()..remove('session');

      expect(
        () => WatchSessionHandoff.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('skips malformed points instead of failing the session', () {
      final payload = validPayload()
        ..['points'] = [
          {'t': '2026-06-03T09:00:00.000Z', 'lat': 41.0, 'lon': -8.0, 'seg': 0},
          {'lat': 41.0},
          {'t': '2026-06-03T09:00:05.000Z', 'lat': 999.0, 'lon': -8.0},
          'not-a-map',
        ];

      final handoff = WatchSessionHandoff.fromJson(payload);

      expect(handoff.points, hasLength(1));
    });

    test('treats a missing complete flag as incomplete', () {
      final payload = validPayload()..remove('complete');

      expect(WatchSessionHandoff.fromJson(payload).isComplete, isFalse);
    });
  });

  test('toJson round-trips through fromJson', () {
    final original = WatchSessionHandoff.fromJson(validPayload());

    final restored = WatchSessionHandoff.fromJson(original.toJson());

    expect(restored.source, original.source);
    expect(restored.sessionId, original.sessionId);
    expect(restored.isComplete, original.isComplete);
    expect(restored.points, hasLength(original.points.length));
  });
}
