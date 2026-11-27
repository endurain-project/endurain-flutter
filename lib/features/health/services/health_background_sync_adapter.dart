import 'package:flutter/services.dart';

/// Channel name, methods and arguments shared with the native background
/// trigger of automatic health import: `HealthBackgroundSyncChannel.kt`
/// (WorkManager) and `HealthBackgroundSyncChannel.swift` (HealthKit
/// background delivery).
class HealthBackgroundSyncChannelContract {
  const HealthBackgroundSyncChannelContract._();

  static const String channelName = 'endurain/health_background_sync';

  /// Dart → native: turns the background trigger on or off
  /// ([argScheduled]).
  static const String setScheduled = 'setScheduled';

  /// Dart → native: this engine runs the background syncs started while it
  /// is up (the app engine, once its Dart side is ready).
  static const String listen = 'listen';

  /// Native → Dart, on a listening engine: run one sync and reply whether it
  /// succeeded.
  static const String run = 'run';

  /// Dart → native, from the headless engine started for one sync: the sync
  /// finished ([argSucceeded]), so the engine can be destroyed.
  static const String reportFinished = 'reportFinished';

  static const String argScheduled = 'scheduled';
  static const String argSucceeded = 'succeeded';

  // Error codes.
  static const String errorInvalidArguments = 'invalid_arguments';
  static const String errorScheduleFailed = 'schedule_failed';
}

/// The native trigger that runs automatic health import while the app is not
/// in the foreground: periodic WorkManager work on Android, HealthKit
/// background delivery of new workouts on iOS.
abstract interface class HealthBackgroundSyncAdapter {
  /// Turns the background trigger on or off. Idempotent.
  Future<void> setScheduled(bool scheduled);

  /// Runs [run] for every background sync the platform starts while this
  /// engine is up, instead of starting a headless engine for it.
  Future<void> listen(Future<bool> Function() run);

  /// Tells the platform that the sync this headless engine was started for
  /// has finished.
  Future<void> reportFinished({required bool succeeded});
}

/// [HealthBackgroundSyncAdapter] over the shared method channel.
class MethodChannelHealthBackgroundSyncAdapter
    implements HealthBackgroundSyncAdapter {
  const MethodChannelHealthBackgroundSyncAdapter({
    MethodChannel channel = const MethodChannel(
      HealthBackgroundSyncChannelContract.channelName,
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<void> setScheduled(bool scheduled) {
    return _channel.invokeMethod<void>(
      HealthBackgroundSyncChannelContract.setScheduled,
      {HealthBackgroundSyncChannelContract.argScheduled: scheduled},
    );
  }

  @override
  Future<void> listen(Future<bool> Function() run) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != HealthBackgroundSyncChannelContract.run) {
        throw MissingPluginException();
      }
      return run();
    });
    return _channel.invokeMethod<void>(
      HealthBackgroundSyncChannelContract.listen,
    );
  }

  @override
  Future<void> reportFinished({required bool succeeded}) {
    return _channel.invokeMethod<void>(
      HealthBackgroundSyncChannelContract.reportFinished,
      {HealthBackgroundSyncChannelContract.argSucceeded: succeeded},
    );
  }
}

/// [HealthBackgroundSyncAdapter] for platforms without a background trigger
/// (desktop, web, the test host): nothing runs in the background.
class UnsupportedHealthBackgroundSyncAdapter
    implements HealthBackgroundSyncAdapter {
  const UnsupportedHealthBackgroundSyncAdapter();

  @override
  Future<void> setScheduled(bool scheduled) async {}

  @override
  Future<void> listen(Future<bool> Function() run) async {}

  @override
  Future<void> reportFinished({required bool succeeded}) async {}
}
