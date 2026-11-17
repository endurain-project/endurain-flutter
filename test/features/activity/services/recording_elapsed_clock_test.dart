import 'package:endurain/features/activity/services/recording_elapsed_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecordingElapsedClock', () {
    late DateTime now;
    late RecordingElapsedClock clock;

    setUp(() {
      now = DateTime.utc(2026, 1, 1, 12);
      clock = RecordingElapsedClock(() => now);
    });

    tearDown(() => clock.cancelTicker());

    test('counts the running segment', () {
      clock.beginSegment(now);
      now = now.add(const Duration(seconds: 42));
      expect(clock.currentSeconds, 42);
    });

    test('freeze keeps the total and stops counting', () {
      clock.beginSegment(now);
      now = now.add(const Duration(seconds: 10));
      expect(clock.freeze(), 10);
      now = now.add(const Duration(seconds: 100));
      expect(clock.currentSeconds, 10);
    });

    test('resuming adds a new segment to the frozen total', () {
      clock.beginSegment(now);
      now = now.add(const Duration(seconds: 10));
      clock.freeze();
      now = now.add(const Duration(seconds: 50));
      clock.beginSegment(now);
      now = now.add(const Duration(seconds: 5));
      expect(clock.currentSeconds, 15);
    });

    test('freeze prefers an authoritative elapsed value', () {
      clock.beginSegment(now);
      expect(clock.freeze(elapsedSeconds: 99), 99);
      expect(clock.currentSeconds, 99);
    });

    test('a start time in the future never yields negative time', () {
      clock.beginSegment(now.add(const Duration(seconds: 30)));
      expect(clock.currentSeconds, 0);
    });

    test('reset clears elapsed time', () {
      clock.beginSegment(now);
      now = now.add(const Duration(seconds: 10));
      clock.freeze();
      clock.reset();
      expect(clock.currentSeconds, 0);
    });

    test('restore resumes from a recovered session', () {
      clock.restore(elapsedBeforeSeconds: 20, segmentStartedAt: now);
      now = now.add(const Duration(seconds: 5));
      expect(clock.currentSeconds, 25);
      clock.restore(elapsedBeforeSeconds: 20, segmentStartedAt: null);
      expect(clock.currentSeconds, 20);
    });
  });
}
