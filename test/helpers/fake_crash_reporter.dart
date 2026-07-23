import 'package:endurain/core/services/crash_reporter.dart';

/// A [CrashReporter] that records interactions for assertions instead of
/// contacting a backend.
class FakeCrashReporter implements CrashReporter {
  final List<({String dsn, String? release, String? environment})> starts = [];
  int stopCount = 0;
  final List<({Object error, String? source})> captures = [];

  bool _active = false;
  String? activeDsn;

  /// When false, [start] refuses to activate, modelling an invalid or
  /// backend-rejected DSN.
  bool startSucceeds = true;

  @override
  bool get isActive => _active;

  @override
  Future<bool> start({
    required String dsn,
    String? release,
    String? environment,
  }) async {
    starts.add((dsn: dsn, release: release, environment: environment));
    if (!startSucceeds) {
      _active = false;
      activeDsn = null;
      return false;
    }
    _active = true;
    activeDsn = dsn;
    return true;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _active = false;
    activeDsn = null;
  }

  @override
  Future<void> capture(
    Object error,
    StackTrace stackTrace, {
    String? source,
  }) async {
    captures.add((error: error, source: source));
  }
}
