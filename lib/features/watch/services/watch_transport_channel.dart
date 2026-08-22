import 'dart:async';

import 'package:endurain/features/watch/models/watch_link_status.dart';
import 'package:endurain/features/watch/models/watch_session_handoff.dart';
import 'package:endurain/features/watch/models/watch_transport_event.dart';
import 'package:endurain/features/watch/services/watch_transport_adapter.dart';
import 'package:flutter/services.dart';

/// Channel names, method/event identifiers, and error codes shared with the
/// native watch transports (Wearable Data Layer on Android, WatchConnectivity
/// on iOS).
///
/// Mirrors the shape of `NativeActivityRecorderChannelContract` so both native
/// bridges follow one convention.
class WatchTransportChannelContract {
  const WatchTransportChannelContract._();

  /// Schema version for method arguments and event payloads. Native code must
  /// reject or migrate mismatched versions.
  static const int payloadVersion = WatchSessionHandoff.currentPayloadVersion;

  static const String methodChannelName = 'endurain/watch_transport/methods';
  static const String eventChannelName = 'endurain/watch_transport/events';

  // Method names — session handoff (implemented).
  static const String linkStatus = 'linkStatus';
  static const String drainHandoffs = 'drainHandoffs';
  static const String acknowledgeHandoff = 'acknowledgeHandoff';

  // Method names — live control/state mirroring. Reserved for the Wear OS and
  // watchOS "remote + live stats" phases; declared here so both native sides
  // agree on the names before either is written.
  static const String sendControlStart = 'control.start';
  static const String sendControlPause = 'control.pause';
  static const String sendControlResume = 'control.resume';
  static const String sendControlStop = 'control.stop';
  static const String sendLiveStats = 'control.liveStats';

  // Method argument keys.
  static const String argVersion = 'version';
  static const String argSessionId = 'sessionId';

  // Event payload keys.
  static const String eventType = 'type';
  static const String eventLinkStatus = 'linkStatus';

  // Event type values.
  static const String eventLinkStatusChanged = 'linkStatusChanged';
  static const String eventHandoffAvailable = 'handoffAvailable';

  // PlatformException codes raised by the native handlers.
  //
  /// Required argument missing or malformed.
  static const String errorInvalidArguments = 'invalid_arguments';

  /// The native side rejected [payloadVersion].
  static const String errorUnsupportedVersion = 'unsupported_version';

  /// The pending-handoff store could not be read.
  static const String errorStoreReadFailed = 'store_read_failed';

  /// The watch could not be reached for a live control message.
  static const String errorWatchUnreachable = 'watch_unreachable';
}

/// [WatchTransportAdapter] backed by platform channels.
///
/// Until the native Wear OS / watchOS transports ship, every call raises
/// [MissingPluginException]; that is translated into the "unsupported" result
/// so the seam is inert rather than error-producing on current builds.
class MethodChannelWatchTransport implements WatchTransportAdapter {
  MethodChannelWatchTransport({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _methodChannel = methodChannel ?? _defaultMethodChannel,
       _eventChannel = eventChannel ?? _defaultEventChannel;

  static const MethodChannel _defaultMethodChannel = MethodChannel(
    WatchTransportChannelContract.methodChannelName,
  );

  static const EventChannel _defaultEventChannel = EventChannel(
    WatchTransportChannelContract.eventChannelName,
  );

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  StreamController<WatchTransportEvent>? _events;
  StreamSubscription<dynamic>? _nativeEvents;

  @override
  Stream<WatchTransportEvent> get events {
    final existing = _events;
    if (existing != null) {
      return existing.stream;
    }
    final controller = StreamController<WatchTransportEvent>.broadcast();
    _events = controller;
    unawaited(_activate(controller));
    return controller.stream;
  }

  /// Activates the native broadcast stream only once the transport is known to
  /// exist.
  ///
  /// `EventChannel.receiveBroadcastStream` reports an activation failure (such
  /// as the [MissingPluginException] raised on a build without the native
  /// bridge) through `FlutterError.reportError` rather than through the
  /// returned stream, which would surface as a false crash report. Probing the
  /// method channel first keeps the seam genuinely inert instead of merely
  /// quiet.
  Future<void> _activate(
    StreamController<WatchTransportEvent> controller,
  ) async {
    if (!await _transportIsPresent() || !identical(_events, controller)) {
      await controller.close();
      return;
    }
    _nativeEvents = _eventChannel.receiveBroadcastStream().listen(
      (payload) {
        final event = _parseEvent(payload);
        if (event != null) {
          controller.add(event);
        }
      },
      onError: controller.addError,
      onDone: () => unawaited(controller.close()),
    );
  }

  /// Whether the native transport answered the probe at all.
  ///
  /// Only a missing bridge or an explicit `unsupported` answer suppresses the
  /// push stream: a transient native failure must not disable watch events for
  /// the rest of the process lifetime.
  Future<bool> _transportIsPresent() async {
    try {
      final result = await _methodChannel.invokeMethod<String>(
        WatchTransportChannelContract.linkStatus,
        {
          WatchTransportChannelContract.argVersion:
              WatchTransportChannelContract.payloadVersion,
        },
      );
      return result != WatchLinkStatus.unsupported.toJson();
    } on MissingPluginException {
      return false;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<WatchLinkStatus> linkStatus() async {
    try {
      final result = await _methodChannel.invokeMethod<String>(
        WatchTransportChannelContract.linkStatus,
        {
          WatchTransportChannelContract.argVersion:
              WatchTransportChannelContract.payloadVersion,
        },
      );
      return WatchLinkStatus.fromJson(result);
    } on MissingPluginException {
      return WatchLinkStatus.unsupported;
    }
  }

  @override
  Future<List<WatchSessionHandoff>> drainPendingHandoffs() async {
    final result = await _invokeDrain();
    if (result == null) {
      return const <WatchSessionHandoff>[];
    }

    final handoffs = <WatchSessionHandoff>[];
    for (final entry in result) {
      if (entry is! Map) {
        continue;
      }
      try {
        handoffs.add(WatchSessionHandoff.fromJson(entry));
      } on FormatException {
        // Skip an unreadable envelope: the native side keeps it queued (it is
        // never acknowledged), so a later app version can still ingest it.
        continue;
      }
    }
    return handoffs;
  }

  /// Returns `null` when the native transport is absent or returned nothing.
  Future<List<Object?>?> _invokeDrain() async {
    try {
      return await _methodChannel.invokeMethod<List<Object?>>(
        WatchTransportChannelContract.drainHandoffs,
        {
          WatchTransportChannelContract.argVersion:
              WatchTransportChannelContract.payloadVersion,
        },
      );
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> acknowledgeHandoff(String sessionId) async {
    try {
      await _methodChannel.invokeMethod<void>(
        WatchTransportChannelContract.acknowledgeHandoff,
        {
          WatchTransportChannelContract.argVersion:
              WatchTransportChannelContract.payloadVersion,
          WatchTransportChannelContract.argSessionId: sessionId,
        },
      );
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> dispose() async {
    // Cancelling the native subscription deactivates the EventChannel on the
    // platform side; the broadcast controller is closed so late listeners get
    // a terminated stream instead of a silent one.
    await _nativeEvents?.cancel();
    _nativeEvents = null;
    final controller = _events;
    _events = null;
    await controller?.close();
  }

  WatchTransportEvent? _parseEvent(Object? payload) {
    if (payload is! Map) {
      return null;
    }
    switch (payload[WatchTransportChannelContract.eventType]) {
      case WatchTransportChannelContract.eventLinkStatusChanged:
        return WatchTransportEvent.linkStatusChanged(
          WatchLinkStatus.fromJson(
            payload[WatchTransportChannelContract.eventLinkStatus],
          ),
        );
      case WatchTransportChannelContract.eventHandoffAvailable:
        return const WatchTransportEvent.handoffAvailable();
      default:
        return null;
    }
  }
}
