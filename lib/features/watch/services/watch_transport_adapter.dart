import 'package:endurain/features/watch/models/watch_link_status.dart';
import 'package:endurain/features/watch/models/watch_session_handoff.dart';
import 'package:endurain/features/watch/models/watch_transport_event.dart';

/// Injectable seam between the phone and a paired companion watch.
///
/// ## Contract
/// - Implementations MUST NOT throw for an unsupported or unavailable
///   platform: return [WatchLinkStatus.unsupported] and an empty handoff list
///   instead, so callers never need a platform check.
/// - [drainPendingHandoffs] is a *read*: the native side keeps a handoff queued
///   until [acknowledgeHandoff] confirms the phone persisted it. This makes the
///   transfer resumable — a crash between drain and persist re-delivers the
///   session rather than losing it.
/// - Implementations MUST NEVER log coordinates or device identifiers.
abstract class WatchTransportAdapter {
  /// Push notifications from the native transport (link changes, pending
  /// handoffs). A broadcast stream; late subscribers do not replay history.
  Stream<WatchTransportEvent> get events;

  /// Current reachability of the paired watch.
  Future<WatchLinkStatus> linkStatus();

  /// Returns every session the watch has handed over and that the phone has
  /// not yet acknowledged.
  Future<List<WatchSessionHandoff>> drainPendingHandoffs();

  /// Confirms that [sessionId] is durably stored on the phone, allowing the
  /// native side (and in turn the watch) to drop its copy.
  Future<void> acknowledgeHandoff(String sessionId);

  Future<void> dispose();
}

/// [WatchTransportAdapter] for platforms with no companion-watch support
/// (desktop, web, the test host runtime) and for builds whose native transport
/// is not present.
class UnsupportedWatchTransport implements WatchTransportAdapter {
  const UnsupportedWatchTransport();

  @override
  Stream<WatchTransportEvent> get events => const Stream.empty();

  @override
  Future<WatchLinkStatus> linkStatus() async => WatchLinkStatus.unsupported;

  @override
  Future<List<WatchSessionHandoff>> drainPendingHandoffs() async =>
      const <WatchSessionHandoff>[];

  @override
  Future<void> acknowledgeHandoff(String sessionId) async {}

  @override
  Future<void> dispose() async {}
}
