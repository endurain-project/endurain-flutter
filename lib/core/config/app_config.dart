/// Describes the transport security policy in effect for a build.
///
/// - [selfHosted]: the default mode for private-network and self-hosted
///   deployments. Plain `http://` connections are permitted, and the user
///   receives a localized warning before proceeding.
/// - [managed]: a stricter mode intended for managed deployments.
///   Plain `http://` connections are rejected before any network call is made.
enum AppTransportMode {
  /// Self-hosted mode: `http://` is warned and allowed.
  selfHosted,

  /// Managed mode: `http://` is rejected before any network call.
  managed,
}

/// Compile-time environment configuration for the Endurain mobile client.
///
/// [AppConfig.defaults] provides production-safe values for self-hosted
/// deployments. A stricter managed build can instantiate [AppConfig] with
/// different values and pass it to `AppServices` before calling any feature
/// code.
///
/// All service defaults must remain identical to the current self-hosted
/// behavior when [AppConfig.defaults] is used.
class AppConfig {
  const AppConfig({
    this.apiBasePath = defaultApiBasePath,
    this.transportMode = AppTransportMode.selfHosted,
    this.allowedTileServerHosts,
    this.cloudBaseUrl,
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
  /// Use [AppTransportMode.managed] in managed builds where
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

  /// Optional origin of the managed ("SaaS") Endurain service for this build.
  ///
  /// When set (e.g. `https://app.endurain.example`), connections whose host
  /// matches this origin are always treated as managed: plain `http://` is
  /// rejected regardless of [transportMode], so the cloud service can never be
  /// reached over insecure transport. When `null` (the self-hosted default),
  /// every URL follows the build-wide [transportMode]. This is the seam a
  /// future server picker uses to pre-fill the managed origin.
  final String? cloudBaseUrl;

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

  /// Whether plain `http://` is permitted when connecting to [url].
  ///
  /// Connections to the managed [cloudBaseUrl] origin are always strict
  /// (returns `false`); every other host follows the build-wide
  /// [allowInsecureTransport] policy. Use this per-URL check at transport
  /// enforcement points (URL resolution, form validation) so the managed
  /// cloud origin stays secure even in self-hosted builds.
  bool allowInsecureTransportFor(String url) {
    if (_isManagedOrigin(url)) {
      return false;
    }
    return allowInsecureTransport;
  }

  /// Whether [url] targets the managed [cloudBaseUrl] origin (host match).
  bool _isManagedOrigin(String url) {
    final cloud = cloudBaseUrl;
    if (cloud == null) {
      return false;
    }
    final target = Uri.tryParse(url);
    final cloudUri = Uri.tryParse(cloud);
    if (target == null || cloudUri == null || !target.hasAuthority) {
      return false;
    }
    return target.host.toLowerCase() == cloudUri.host.toLowerCase();
  }

  /// The current Endurain API version path prefix.
  static const String defaultApiBasePath = '/api/v1';

  /// Production-safe defaults — identical to the existing self-hosted behavior.
  static const AppConfig defaults = AppConfig();
}
