import 'package:endurain/features/activity/services/activity_duration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reportedActivityDurationSeconds', () {
    test('uses the wall-clock elapsed time in the normal case', () {
      // GPS acquisition lag makes the point span shorter than the timer.
      expect(
        reportedActivityDurationSeconds(
          statsDurationSeconds: 2970,
          elapsedDurationSeconds: 3000,
        ),
        3000,
      );
    });

    test('falls back to the point span when it is longer', () {
      // A session recovered after the app was killed: points outlived the
      // timer state.
      expect(
        reportedActivityDurationSeconds(
          statsDurationSeconds: 3600,
          elapsedDurationSeconds: 120,
        ),
        3600,
      );
    });

    test('clamps negative inputs to zero', () {
      expect(
        reportedActivityDurationSeconds(
          statsDurationSeconds: -5,
          elapsedDurationSeconds: -10,
        ),
        0,
      );
      expect(
        reportedActivityDurationSeconds(
          statsDurationSeconds: 30,
          elapsedDurationSeconds: -10,
        ),
        30,
      );
    });

    test('returns zero when nothing was recorded', () {
      expect(
        reportedActivityDurationSeconds(
          statsDurationSeconds: 0,
          elapsedDurationSeconds: 0,
        ),
        0,
      );
    });
  });
}
