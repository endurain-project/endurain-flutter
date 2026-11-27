import 'package:endurain/features/activity/models/recording_live_activity_content.dart';
import 'package:endurain/features/activity/services/native_activity_recorder_channel.dart';
import 'package:flutter/services.dart';

/// Shows a recording on the system's live surfaces: the Live Activity on the
/// iPhone Lock Screen and in the Dynamic Island.
abstract class RecordingLiveActivityAdapter {
  /// Shows [content] for its recording. The native side starts the Live
  /// Activity with the first content of a recording and ends it when the
  /// recording stops or is discarded.
  Future<void> update(RecordingLiveActivityContent content);
}

/// No-op adapter for platforms without a Live Activity.
class UnsupportedRecordingLiveActivityAdapter
    implements RecordingLiveActivityAdapter {
  const UnsupportedRecordingLiveActivityAdapter();

  @override
  Future<void> update(RecordingLiveActivityContent content) async {}
}

/// [RecordingLiveActivityAdapter] backed by the native recorder method
/// channel, which owns the iOS Live Activity.
class MethodChannelRecordingLiveActivityAdapter
    implements RecordingLiveActivityAdapter {
  MethodChannelRecordingLiveActivityAdapter({MethodChannel? methodChannel})
    : _methodChannel =
          methodChannel ??
          const MethodChannel(
            NativeActivityRecorderChannelContract.methodChannelName,
          );

  final MethodChannel _methodChannel;

  @override
  Future<void> update(RecordingLiveActivityContent content) {
    return _methodChannel.invokeMethod<void>(
      NativeActivityRecorderChannelContract.updateLiveActivity,
      {
        'version': NativeActivityRecorderChannelContract.payloadVersion,
        ...content.toChannelMap(),
      },
    );
  }
}
