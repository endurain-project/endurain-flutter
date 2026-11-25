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

  /// Keeps the app running while the countdown runs in the background.
  ///
  /// Nothing records during the countdown, so on its own the app would look
  /// idle: iOS suspends it soon after the screen locks, and newer Android
  /// versions can freeze it soon after the user switches apps. Both platforms
  /// therefore run location updates that are thrown away, which also warms up
  /// GPS for the first point. On Android this runs in the recorder's
  /// foreground service, and the recording then starts inside that same
  /// service, so it can start on time even with another app in front.
  ///
  /// Call it while the app is in the foreground.
  Future<void> beginWarmUp();

  /// Ends [beginWarmUp] when no recording started from it. Safe to call when
  /// no warm-up is running, and after the recording has started.
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
