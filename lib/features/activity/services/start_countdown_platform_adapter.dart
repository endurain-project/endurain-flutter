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
  /// [countdownSeconds] is the countdown's full length. Android sizes a
  /// safety timeout from it so a warm-up that is never ended (or taken over by
  /// a recording) cannot keep the foreground service running indefinitely.
  ///
  /// Call it while the app is in the foreground.
  Future<void> beginWarmUp({required int countdownSeconds});

  /// Ends [beginWarmUp] when no recording started from it. Safe to call when
  /// no warm-up is running, and after the recording has started.
  Future<void> endWarmUp();

  /// Asks for the Android 13+ notification permission, which keeps the
  /// recording's foreground notification visible. Call it right before a
  /// recording or its countdown starts, while the user is looking at the app.
  /// Resolves to whether the permission is granted; recording proceeds either
  /// way. Always true where there is nothing to ask (older Android, iOS).
  Future<bool> requestNotificationPermission();
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
  Future<void> beginWarmUp({required int countdownSeconds}) async {}

  @override
  Future<void> endWarmUp() async {}

  @override
  Future<bool> requestNotificationPermission() async => true;
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
  Future<void> beginWarmUp({required int countdownSeconds}) {
    return _methodChannel.invokeMethod<void>(
      NativeActivityRecorderChannelContract.beginStartWarmUp,
      {'countdownSeconds': countdownSeconds},
    );
  }

  @override
  Future<void> endWarmUp() {
    return _methodChannel.invokeMethod<void>(
      NativeActivityRecorderChannelContract.endStartWarmUp,
    );
  }

  @override
  Future<bool> requestNotificationPermission() async {
    try {
      return await _methodChannel.invokeMethod<bool>(
            NativeActivityRecorderChannelContract.requestNotificationPermission,
          ) ??
          false;
    } on MissingPluginException {
      // iOS has no such prompt to show here.
      return true;
    }
  }
}
