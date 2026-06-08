/// Describes the transport security policy in effect for a build.
///
/// - [selfHosted]: the default mode for private-network and self-hosted
///   deployments. Plain `http://` connections are permitted, and the user
///   receives a localized warning before proceeding.
/// - [managed]: a stricter mode intended for SaaS or managed enterprise builds.
///   Plain `http://` connections are rejected before any network call is made.
enum AppTransportMode {
  /// Self-hosted mode: `http://` is warned and allowed.
  selfHosted,

  /// Managed/SaaS mode: `http://` is rejected before any network call.
  managed,
}

/// Compile-time environment configuration for the Endurain mobile client.
///
/// [AppConfig.defaults] provides production-safe values for self-hosted
/// deployments. A stricter managed or SaaS build can instantiate [AppConfig]
/// with different values and pass it to `AppServices` before calling any
/// feature code.
///
/// All service defaults must remain identical to the current self-hosted
/// behavior when [AppConfig.defaults] is used.
class AppConfig {
  const AppConfig({
    this.apiBasePath = defaultApiBasePath,
    this.transportMode = AppTransportMode.selfHosted,
    this.allowedTileServerHosts,
  });

  /// Base path prefix for all Endurain API endpoints.
  ///
  /// Combined with the server origin to form full endpoint URLs:
  /// `<serverUrl><apiBasePath>/auth/login`.
  ///
  /// Exists here so a future API version bump changes one constant rather than
  /// every service that builds endpoint strings.
  final String apiBasePath;

  /// The transport security policy for this build.
  ///
  /// Use [AppTransportMode.selfHosted] (the default) for self-hosted
  /// deployments where plain-HTTP connections are warned and allowed.
  /// Use [AppTransportMode.managed] in SaaS or enterprise builds where
  /// plain-HTTP must be rejected before any network call.
  final AppTransportMode transportMode;

  /// Optional set of allowed tile-server hostnames for this build.
  ///
  /// When `null` (the default for self-hosted), any tile server host is
  /// permitted. When set, only hostnames in this set are accepted; attempts
  /// to save an out-of-policy host are rejected by the settings UI.
  ///
  /// Managed builds can set this to restrict users to approved tile servers.
  final Set<String>? allowedTileServerHosts;

  /// Returns `true` when [host] is acceptable as a tile server for this build.
  ///
  /// Always returns `true` when [allowedTileServerHosts] is `null` (the
  /// self-hosted default). Otherwise returns `true` only if [host] is
  /// contained in the allowed set.
  bool isTileServerHostAllowed(String host) {
    final allowed = allowedTileServerHosts;
    return allowed == null || allowed.contains(host);
  }

  /// Whether the app permits connections to `http://` server URLs.
  ///
  /// Derived from [transportMode]: `true` in [AppTransportMode.selfHosted]
  /// and `false` in [AppTransportMode.managed].
  ///
  /// The login flow checks this flag: when `false`, an `http://` server URL is
  /// rejected as a validation error; when `true` (default), the user receives
  /// a localized warning and can confirm before proceeding.
  bool get allowInsecureTransport =>
      transportMode == AppTransportMode.selfHosted;

  /// The current Endurain API version path prefix.
  static const String defaultApiBasePath = '/api/v1';

  /// Production-safe defaults — identical to the existing self-hosted behavior.
  static const AppConfig defaults = AppConfig();
}
