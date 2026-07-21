import 'package:endurain/core/services/modules/activity_module.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityModule sensor handoff', () {
    test('heartRateHandoffReleased detects the end of a recording handoff', () {
      // The first observation (null previous) is never treated as a release.
      expect(
        ActivityModule.heartRateHandoffReleased(
          null,
          ActivityRecordingStatus.recording,
        ),
        isFalse,
      );

      // Leaving an owning phase (recording/paused/stopping) for a terminal one
      // releases the native sensor handoff.
      for (final previous in const [
        ActivityRecordingStatus.recording,
        ActivityRecordingStatus.paused,
        ActivityRecordingStatus.stopping,
      ]) {
        expect(
          ActivityModule.heartRateHandoffReleased(
            previous,
            ActivityRecordingStatus.completed,
          ),
          isTrue,
          reason: '$previous -> completed should release',
        );
      }
      expect(
        ActivityModule.heartRateHandoffReleased(
          ActivityRecordingStatus.recording,
          ActivityRecordingStatus.failed,
        ),
        isTrue,
      );
      expect(
        ActivityModule.heartRateHandoffReleased(
          ActivityRecordingStatus.stopping,
          ActivityRecordingStatus.idle,
        ),
        isTrue,
      );

      // Transitions within owning phases, or between terminal phases, do not.
      expect(
        ActivityModule.heartRateHandoffReleased(
          ActivityRecordingStatus.recording,
          ActivityRecordingStatus.paused,
        ),
        isFalse,
      );
      expect(
        ActivityModule.heartRateHandoffReleased(
          ActivityRecordingStatus.recording,
          ActivityRecordingStatus.stopping,
        ),
        isFalse,
      );
      expect(
        ActivityModule.heartRateHandoffReleased(
          ActivityRecordingStatus.completed,
          ActivityRecordingStatus.idle,
        ),
        isFalse,
      );
      expect(
        ActivityModule.heartRateHandoffReleased(
          ActivityRecordingStatus.idle,
          ActivityRecordingStatus.recording,
        ),
        isFalse,
      );
    });

    test('usesNativeHeartRateHandoff is Android-only', () {
      // Only Android releases the Dart BLE link to the native foreground
      // service (FOREGROUND_SERVICE_CONNECTED_DEVICE). iOS and every other
      // platform keep the Dart sensor connected and stream its readings into
      // the recording pipeline, so live values stay visible while recording.
      expect(
        ActivityModule.usesNativeHeartRateHandoff(TargetPlatform.android),
        isTrue,
      );
      for (final platform in const [
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.windows,
        TargetPlatform.fuchsia,
      ]) {
        expect(
          ActivityModule.usesNativeHeartRateHandoff(platform),
          isFalse,
          reason: '$platform should keep the Dart sensor connection',
        );
      }
    });
  });
}
