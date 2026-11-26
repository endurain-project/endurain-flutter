import 'package:endurain/features/activity/services/activity_upload_retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityUploadBackoff', () {
    final backoff = ActivityUploadBackoff(random: () => 0);

    test('starts at one minute and doubles', () {
      expect(backoff.delayAfter(1), const Duration(minutes: 1));
      expect(backoff.delayAfter(2), const Duration(minutes: 2));
      expect(backoff.delayAfter(3), const Duration(minutes: 4));
    });

    test('is capped at six hours however many failures there were', () {
      expect(backoff.delayAfter(10), const Duration(hours: 6));
      expect(backoff.delayAfter(500), const Duration(hours: 6));
    });

    test('adds jitter without exceeding the cap', () {
      final jittered = ActivityUploadBackoff(random: () => 1);

      expect(jittered.delayAfter(1), const Duration(seconds: 72));
      expect(jittered.delayAfter(500), const Duration(hours: 6));
    });
  });
}
