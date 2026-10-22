import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper over `connectivity_plus` that exposes a boolean online signal.
///
/// [onOnlineChanged] emits `true` when the device has at least one active
/// network transport and `false` when fully offline. It is consumed by the
/// activity upload queue to drain pending/failed uploads the moment
/// connectivity is restored.
///
/// Errors from the platform layer are swallowed so a connectivity-plugin
/// failure degrades to "no signal" (the queue still retries on app-resume)
/// rather than surfacing an unhandled stream error.
///
/// The underlying change stream is injectable so the mapping can be unit
/// tested without platform channels.
class ConnectivityService {
  ConnectivityService({Stream<List<ConnectivityResult>>? changes})
    : _changes = changes ?? Connectivity().onConnectivityChanged;

  final Stream<List<ConnectivityResult>> _changes;

  /// Emits `true` when online and `false` when offline.
  Stream<bool> get onOnlineChanged =>
      _changes.map(_isOnline).handleError((Object _) {});

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
