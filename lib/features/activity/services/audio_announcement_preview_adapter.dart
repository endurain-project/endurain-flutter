import 'package:endurain/features/activity/models/audio_announcement_config.dart';
import 'package:endurain/features/activity/services/native_activity_recorder_channel.dart';
import 'package:flutter/services.dart';

/// Injectable boundary over the platform text-to-speech engine used to speak
/// one sample announcement from the settings screen.
///
/// Every announcement failure path in the native recorder is silent by design
/// (speech must never be able to fail a recording), so without this seam a
/// device with no speech engine, a muted media stream, or missing voice data
/// is indistinguishable from a working one. The preview is the only place the
/// user can confirm announcements are audible before starting an activity.
abstract class AudioAnnouncementPreviewAdapter {
  /// Speaks a sample announcement built from [config].
  ///
  /// Completes once the utterance is queued, not once it finishes.
  Future<void> speakPreview(AudioAnnouncementConfig config);
}

/// A no-op [AudioAnnouncementPreviewAdapter] for platforms with no native
/// recorder channel (the host test runtime, desktop, web).
class UnsupportedAudioAnnouncementPreviewAdapter
    implements AudioAnnouncementPreviewAdapter {
  const UnsupportedAudioAnnouncementPreviewAdapter();

  @override
  Future<void> speakPreview(AudioAnnouncementConfig config) async {}
}

/// [AudioAnnouncementPreviewAdapter] backed by the native recorder method
/// channel.
///
/// Reuses the recorder channel because the native speech engine lives there
/// and is shared with live announcements. The native handler never touches the
/// durable session store, so previewing during an active recording is safe.
class MethodChannelAudioAnnouncementPreviewAdapter
    implements AudioAnnouncementPreviewAdapter {
  MethodChannelAudioAnnouncementPreviewAdapter({MethodChannel? methodChannel})
    : _methodChannel =
          methodChannel ??
          const MethodChannel(
            NativeActivityRecorderChannelContract.methodChannelName,
          );

  final MethodChannel _methodChannel;

  @override
  Future<void> speakPreview(AudioAnnouncementConfig config) {
    return _methodChannel.invokeMethod<void>(
      NativeActivityRecorderChannelContract.speakAnnouncementPreview,
      {
        'version': NativeActivityRecorderChannelContract.payloadVersion,
        'audioAnnouncements': config.toChannelMap(),
      },
    );
  }
}
