import 'package:endurain/features/activity/services/native_activity_recorder_channel.dart';
import 'package:flutter/services.dart';

/// Native support for the countdown shown before a recording starts.
abstract class StartCountdownPlatformAdapter {
  /// Speaks [text] through the same native speech engine as the in-recording
  /// announcements. Completes once the utterance is queued.
  Future<void> speakCue(
    String text, {
    required bool duckOtherAudio,
    required String languageTag,
  });

  /// Keeps the app running while the countdown runs with the screen locked.
  ///
  /// iOS suspends an app soon after the screen locks unless it is doing
  /// something allowed in the background. Nothing records during the
  /// countdown, so iOS starts location updates that are thrown away; that
  /// keeps the app awake and warms up GPS for the first point. Android keeps
  /// timers running with the screen off and does nothing here.
  Future<void> beginWarmUp();

  /// Ends [beginWarmUp]. Safe to call when no warm-up is running.
  Future<void> endWarmUp();
}

/// No-op adapter for platforms without the native recorder channel.
class UnsupportedStartCountdownPlatformAdapter
    implements StartCountdownPlatformAdapter {
  const UnsupportedStartCountdownPlatformAdapter();

  @override
  Future<void> speakCue(
    String text, {
    required bool duckOtherAudio,
    required String languageTag,
  }) async {}

  @override
  Future<void> beginWarmUp() async {}

  @override
  Future<void> endWarmUp() async {}
}

/// [StartCountdownPlatformAdapter] backed by the native recorder method
/// channel, which hosts the speech engine. None of these methods touch the
/// durable recording session.
class MethodChannelStartCountdownPlatformAdapter
    implements StartCountdownPlatformAdapter {
  MethodChannelStartCountdownPlatformAdapter({MethodChannel? methodChannel})
    : _methodChannel =
          methodChannel ??
          const MethodChannel(
            NativeActivityRecorderChannelContract.methodChannelName,
          );

  final MethodChannel _methodChannel;

  @override
  Future<void> speakCue(
    String text, {
    required bool duckOtherAudio,
    required String languageTag,
  }) {
    return _methodChannel.invokeMethod<void>(
      NativeActivityRecorderChannelContract.speakCue,
      {
        'version': NativeActivityRecorderChannelContract.payloadVersion,
        'text': text,
        'duckOtherAudio': duckOtherAudio,
        'languageTag': languageTag,
      },
    );
  }

  @override
  Future<void> beginWarmUp() {
    return _methodChannel.invokeMethod<void>(
      NativeActivityRecorderChannelContract.beginStartWarmUp,
    );
  }

  @override
  Future<void> endWarmUp() {
    return _methodChannel.invokeMethod<void>(
      NativeActivityRecorderChannelContract.endStartWarmUp,
    );
  }
}
