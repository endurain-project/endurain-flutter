import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/services/movement_auto_pause_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MovementAutoPauseDetector', () {
    final base = DateTime.utc(2026, 6, 3, 9);

    RecordedActivityPoint point({
      double latitude = 38.7,
      double longitude = -9.1,
      int second = 0,
      double? speed,
      double? accuracy = 5,
    }) {
      return RecordedActivityPoint(
        timestamp: base.add(Duration(seconds: second)),
        latitude: latitude,
        longitude: longitude,
        segmentIndex: 0,
        speedMetersPerSecond: speed,
        horizontalAccuracyMeters: accuracy,
      );
    }

    group('onActivePoint (auto-pause)', () {
      test('disabled config never auto-pauses', () {
        final detector = MovementAutoPauseDetector(
          config: const MovementAutoPauseConfig(
            enabled: false,
            pauseDelay: Duration(seconds: 1),
          ),
        )..reset(movementAt: base);

        for (var second = 0; second <= 10; second++) {
          final transition = detector.onActivePoint(
            point(second: second, speed: 0),
          );
          expect(transition, MovementAutoPauseTransition.none);
        }
      });

      test('auto-pauses once stillness persists for the configured delay', () {
        final detector = MovementAutoPauseDetector(
          config: const MovementAutoPauseConfig(
            enabled: true,
            pauseDelay: Duration(seconds: 5),
          ),
        )..reset(movementAt: base);

        expect(
          detector.onActivePoint(point(second: 1, speed: 0)),
          MovementAutoPauseTransition.none,
        );
        expect(
          detector.onActivePoint(point(second: 4, speed: 0)),
          MovementAutoPauseTransition.none,
        );
        expect(
          detector.onActivePoint(point(second: 5, speed: 0)),
          MovementAutoPauseTransition.autoPause,
        );
      });

      test('reported speed above the threshold resets the stillness timer', () {
        final detector = MovementAutoPauseDetector(
          config: const MovementAutoPauseConfig(
            enabled: true,
            pauseDelay: Duration(seconds: 5),
          ),
        )..reset(movementAt: base);

        detector.onActivePoint(point(second: 3, speed: 0));
        detector.onActivePoint(point(second: 4, speed: 2));
        expect(
          detector.onActivePoint(point(second: 8, speed: 0)),
          MovementAutoPauseTransition.none,
        );
        expect(
          detector.onActivePoint(point(second: 9, speed: 0)),
          MovementAutoPauseTransition.autoPause,
        );
      });

      test('unreliable accuracy is never counted as movement', () {
        final detector = MovementAutoPauseDetector(
          config: const MovementAutoPauseConfig(
            enabled: true,
            pauseDelay: Duration(seconds: 5),
            maxAccuracyMeters: 30,
          ),
        )..reset(movementAt: base);

        // A fast-looking but inaccurate fix must not reset the stillness timer.
        detector.onActivePoint(point(second: 1, speed: 10, accuracy: 500));
        expect(
          detector.onActivePoint(point(second: 5, speed: 0)),
          MovementAutoPauseTransition.autoPause,
        );
      });

      test(
        'displacement-derived speed is used when reported speed is absent',
        () {
          final detector = MovementAutoPauseDetector(
            config: const MovementAutoPauseConfig(
              enabled: true,
              pauseDelay: Duration(seconds: 5),
              movingSpeedThresholdMetersPerSecond: 0.6,
            ),
          )..reset(movementAt: base);

          // ~0.0009 degrees of latitude is roughly 100 meters; moving that far
          // in one second is far above the 0.6 m/s threshold, so the timer
          // resets.
          detector.onActivePoint(point(second: 0, latitude: 38.7));
          expect(
            detector.onActivePoint(point(second: 1, latitude: 38.7009)),
            MovementAutoPauseTransition.none,
          );
          // Two stationary (displacement ~0) fixes after that should reach the
          // configured delay and auto-pause.
          detector.onActivePoint(point(second: 2, latitude: 38.7009));
          expect(
            detector.onActivePoint(point(second: 6, latitude: 38.7009)),
            MovementAutoPauseTransition.autoPause,
          );
        },
      );
    });

    group('onAutoPausedPoint (auto-resume)', () {
      test('auto-resumes only after enough consecutive moving samples', () {
        final detector = MovementAutoPauseDetector(
          config: const MovementAutoPauseConfig(
            enabled: true,
            consecutiveMovingSamplesToResume: 3,
          ),
        )..reset(movementAt: base);

        expect(
          detector.onAutoPausedPoint(point(second: 1, speed: 2)),
          MovementAutoPauseTransition.none,
        );
        expect(
          detector.onAutoPausedPoint(point(second: 2, speed: 2)),
          MovementAutoPauseTransition.none,
        );
        expect(
          detector.onAutoPausedPoint(point(second: 3, speed: 2)),
          MovementAutoPauseTransition.autoResume,
        );
      });

      test('a single still sample resets the consecutive-moving counter', () {
        final detector = MovementAutoPauseDetector(
          config: const MovementAutoPauseConfig(
            enabled: true,
            consecutiveMovingSamplesToResume: 3,
          ),
        )..reset(movementAt: base);

        detector.onAutoPausedPoint(point(second: 1, speed: 2));
        detector.onAutoPausedPoint(point(second: 2, speed: 2));
        // Movement noise briefly drops out; hysteresis must not resume yet.
        detector.onAutoPausedPoint(point(second: 3, speed: 0));
        expect(
          detector.onAutoPausedPoint(point(second: 4, speed: 2)),
          MovementAutoPauseTransition.none,
        );
        expect(
          detector.onAutoPausedPoint(point(second: 5, speed: 2)),
          MovementAutoPauseTransition.none,
        );
        expect(
          detector.onAutoPausedPoint(point(second: 6, speed: 2)),
          MovementAutoPauseTransition.autoResume,
        );
      });
    });

    test('reset clears stillness and consecutive-movement history', () {
      final detector = MovementAutoPauseDetector(
        config: const MovementAutoPauseConfig(
          enabled: true,
          pauseDelay: Duration(seconds: 1),
        ),
      )..reset(movementAt: base);
      detector.onActivePoint(point(second: 5, speed: 0));

      // A manual pause/resume resets tracking; the next active point must not
      // immediately auto-pause using stale history.
      detector.reset(movementAt: base.add(const Duration(seconds: 100)));
      expect(
        detector.onActivePoint(point(second: 100, speed: 0)),
        MovementAutoPauseTransition.none,
      );
    });
  });
}
