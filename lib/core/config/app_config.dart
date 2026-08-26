/// Runtime configuration for the Endurain mobile client.
///
/// A single published app supports both the official managed service
/// ("Endurain Cloud") and user-run self-hosted instances, chosen at runtime
/// (the model Mastodon uses). Transport security is therefore decided per
/// connection rather than per build: the configured [cloudBaseUrl] is always
/// reached over HTTPS, while self-hosted instances may use plain `http://`
/// (the login flow warns the user first).
///
/// [AppConfig.defaults] provides production-safe values. The official cloud
/// origin is supplied through [cloudBaseUrl]; no managed service exists yet, so
/// every current build leaves it unset and treats every origin as self-hosted.
class AppConfig {
  const AppConfig({
    this.apiBasePath = defaultApiBasePath,
    this.allowedTileServerHosts,
    this.healthSyncEnabled = true,
    this.cloudBaseUrl,
    this.crashReportingDsn,
  });

  /// Base path prefix for all Endurain API endpoints.
  ///
  /// Combined with the server origin to form full endpoint URLs:
  /// `<serverUrl><apiBasePath>/auth/login`.
  ///
  /// Exists here so a future API version bump changes one constant rather than
  /// every service that builds endpoint strings.
  final String apiBasePath;

  /// Optional set of allowed tile-server hostnames for this build.
  ///
  /// When `null` (the default for self-hosted), any tile server host is
  /// permitted. When set, only hostnames in this set are accepted; attempts
  /// to save an out-of-policy host are rejected by the settings UI.
  ///
  /// A build can set this to restrict users to approved tile servers.
  final Set<String>? allowedTileServerHosts;

  /// Safety / rollout flag for the Health platform sync feature.
  ///
  /// Defaults to `true` for all builds.
  ///
  /// Uses:
  /// - Kill switch: disable without a code revert by passing
  ///   `--dart-define=ENABLE_HEALTH_SYNC=false` at build time.
  /// - Clean degradation: forces a tested "off" code path so GPS recording and
  ///   manual upload keep working when health sync is disabled.
  /// - Testing: disable in unit/widget tests that must not touch native APIs.
  ///
  /// Runtime availability is decided separately via `getSdkStatus()` — this
  /// flag only gates whether the feature is wired up at all.
  final bool healthSyncEnabled;

  /// Origin of the official managed ("Endurain Cloud") service, injected at
  /// build time from `ENDURAIN_CLOUD_BASE_URL` (`--dart-define`).
  ///
  /// When set, connections whose host matches this origin are always required
  /// to use HTTPS: plain `http://` is rejected so the cloud service can never
  /// be reached over insecure transport. `null` or empty — the current default,
  /// since no managed service exists — treats every URL as a user-chosen
  /// self-hosted instance.
  ///
  /// Setting this must be paired with the OS-level pins in
  /// `android/app/src/main/res/xml/network_security_config.xml` and
  /// `ios/Runner/Info.plist`; `test/architecture/android_manifest_test.dart`
  /// enforces that the three agree.
  final String? cloudBaseUrl;

  /// Default DSN for the managed ("Endurain Cloud") diagnostics endpoint,
  /// `diagnostics.endurain.com`.
  ///
  /// Opt-in remote crash reporting is Sentry-protocol based and always targets
  /// this managed Endurain endpoint; users do not configure a DSN of their own.
  ///
  /// Injected at build time from the `ENDURAIN_CRASH_REPORTING_DSN` environment
  /// value (`--dart-define`), which the official CI supplies for published
  /// builds. It is deliberately NOT hardcoded in source: builds from source
  /// (forks, F-Droid) omit it, so no third-party build points crash reports at
  /// the Endurain-operated endpoint by default. A Sentry DSN is a public client
  /// identifier — it only permits *sending* events, never reading them — so
  /// baking it into official release binaries carries no secret-exposure risk.
  ///
  /// A `null` or empty value means "no managed default": remote reporting stays
  /// inactive because there is no endpoint to send to. Nothing is ever
  /// transmitted until the user opts in AND this managed DSN exists.
  final String? crashReportingDsn;

  /// Returns `true` when [host] is acceptable as a tile server for this build.
  ///
  /// Always returns `true` when [allowedTileServerHosts] is `null` (the
  /// self-hosted default). Otherwise returns `true` only if [host] is
  /// contained in the allowed set.
  bool isTileServerHostAllowed(String host) {
    final allowed = allowedTileServerHosts;
    return allowed == null || allowed.contains(host);
  }

  /// Whether plain `http://` is permitted when connecting to [url].
  ///
  /// The configured [cloudBaseUrl] origin is always strict (returns `false`):
  /// the official cloud service is HTTPS-only. Every other host is treated as a
  /// user-chosen self-hosted instance where `http://` is permitted (the login
  /// flow warns the user first). Use this per-URL check at transport
  /// enforcement points (URL resolution, form validation).
  bool allowInsecureTransportFor(String url) => !_isCloudOrigin(url);

  bool isManagedOrigin(String url) => _isCloudOrigin(url);

  /// Whether [url] targets the official [cloudBaseUrl] origin (host match).
  bool _isCloudOrigin(String url) {
    final cloud = cloudBaseUrl;
    // An empty value is what an unset `--dart-define` yields; treat it as unset.
    if (cloud == null || cloud.isEmpty) {
      return false;
    }
    final target = Uri.tryParse(url);
    final cloudUri = Uri.tryParse(cloud);
    if (target == null || cloudUri == null || !target.hasAuthority) {
      return false;
    }
    return _canonicalHost(target.host) == _canonicalHost(cloudUri.host);
  }

  String _canonicalHost(String host) =>
      host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');

  /// The current Endurain API version path prefix.
  static const String defaultApiBasePath = '/api/v1';

  /// Production-safe defaults — identical to the existing self-hosted behavior.
  static const AppConfig defaults = AppConfig();
}
