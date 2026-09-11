/// Availability of the link to a paired companion watch.
///
/// Deliberately coarse: the phone only needs to know whether a handoff can be
/// expected right now, not the full pairing topology of the platform.
enum WatchLinkStatus {
  /// The running platform has no watch companion integration (desktop, web,
  /// the test host runtime, or a build whose native side is not present).
  unsupported,

  /// The platform supports companion watches but the framework is unavailable
  /// (for example Wearable Data Layer services missing on the device).
  unavailable,

  /// No watch is paired with this phone.
  unpaired,

  /// A watch is paired but the Endurain watch app is not installed on it.
  appNotInstalled,

  /// The watch app is installed but currently out of range or unreachable.
  /// Handoffs may still be delivered later; the watch queues them.
  disconnected,

  /// The watch app is installed and reachable right now.
  connected;

  /// Whether a live control message could plausibly be delivered right now.
  bool get isReachable => this == WatchLinkStatus.connected;

  static WatchLinkStatus fromJson(Object? value) {
    for (final status in WatchLinkStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return WatchLinkStatus.unsupported;
  }

  String toJson() => name;
}
