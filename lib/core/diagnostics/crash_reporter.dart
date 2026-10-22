/// Boundary around a remote crash / error reporting backend.
///
/// Feature and app code depend only on this interface, so the concrete
/// transport is swappable and fully injectable in tests. The shipped
/// implementation (`SentryCrashReporter`) speaks the Sentry protocol, which is
/// understood by the managed Endurain diagnostics endpoint and by self-hosted,
/// Sentry-compatible backends such as GlitchTip.
///
/// Remote reporting is strictly opt-in and independent of the local
/// diagnostics recorder: the user may enable neither, either, or both. Every
/// method is safe to call when inactive — it simply no-ops — so callers never
/// have to branch on state.
abstract interface class CrashReporter {
  /// Whether a reporting session is currently active (started and sending).
  bool get isActive;

  /// Starts a reporting session targeting [dsn].
  ///
  /// A no-op that returns `true` when already active for the same [dsn].
  /// Returns `false` when the session could not be started (e.g. an invalid
  /// DSN); the caller keeps working with reporting inactive.
  Future<bool> start({
    required String dsn,
    String? release,
    String? environment,
  });

  /// Stops the active session, flushing anything pending. Safe when inactive.
  Future<void> stop();

  /// Reports a captured [error] with its [stackTrace]. No-op when inactive.
  ///
  /// [source] is an optional low-cardinality tag describing where the error was
  /// caught (e.g. `flutter`, `root_zone`), mirroring the local diagnostics
  /// sources so the two destinations line up.
  Future<void> capture(Object error, StackTrace stackTrace, {String? source});
}

/// A [CrashReporter] that discards everything.
///
/// Used when remote reporting is disabled and as the safe default on platforms
/// or test runs where no real backend should be contacted.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  bool get isActive => false;

  @override
  Future<bool> start({
    required String dsn,
    String? release,
    String? environment,
  }) async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> capture(
    Object error,
    StackTrace stackTrace, {
    String? source,
  }) async {}
}

/// Whether [dsn] is a structurally usable Sentry DSN.
///
/// A usable DSN is an absolute `http`/`https` URL that carries a public key in
/// its user-info component and a non-empty project path (e.g.
/// `https://<publicKey>@diagnostics.endurain.com/<projectId>`). This is a cheap
/// structural gate so remote reporting never attempts to start with a blank or
/// host-only value; the backend still has the final say on the key.
bool isUsableCrashReportingDsn(String? dsn) {
  if (dsn == null) {
    return false;
  }
  final trimmed = dsn.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasAuthority) {
    return false;
  }
  if (!uri.isScheme('http') && !uri.isScheme('https')) {
    return false;
  }
  if (uri.userInfo.isEmpty) {
    return false;
  }
  final projectPath = uri.path.replaceAll('/', '').trim();
  return projectPath.isNotEmpty;
}
