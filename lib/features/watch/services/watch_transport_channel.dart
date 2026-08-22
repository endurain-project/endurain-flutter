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

  Stream<WatchTransportEvent>? _events;

  @override
  Stream<WatchTransportEvent> get events {
    return _events ??= _eventChannel
        .receiveBroadcastStream()
        // A build without the native transport must look inert, not broken.
        .handleError(
          (Object _) {},
          test: (Object error) => error is MissingPluginException,
        )
        .map(_parseEvent)
        .where((event) => event != null)
        .cast<WatchTransportEvent>();
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
  // Intentional no-op: the EventChannel is a system broadcast owned by the
  // native transport, which manages its own lifecycle. Cancelling here would
  // break other listeners sharing the channel.
  Future<void> dispose() async {}

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
