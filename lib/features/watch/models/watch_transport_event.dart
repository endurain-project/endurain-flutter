import 'package:endurain/features/watch/models/watch_link_status.dart';

/// Kinds of event the watch transport can push to the phone.
enum WatchTransportEventType {
  /// The reachability of the paired watch changed.
  linkStatusChanged,

  /// The native side holds at least one pending session handoff. The phone
  /// responds by calling `WatchTransportAdapter.drainPendingHandoffs`.
  handoffAvailable,
}

/// A single event emitted by `WatchTransportAdapter.events`.
class WatchTransportEvent {
  const WatchTransportEvent._(this.type, this.linkStatus);

  const WatchTransportEvent.linkStatusChanged(WatchLinkStatus status)
    : this._(WatchTransportEventType.linkStatusChanged, status);

  const WatchTransportEvent.handoffAvailable()
    : this._(WatchTransportEventType.handoffAvailable, null);

  final WatchTransportEventType type;

  /// Set only for [WatchTransportEventType.linkStatusChanged].
  final WatchLinkStatus? linkStatus;
}
