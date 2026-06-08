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
    this.allowInsecureTransport = true,
  });

  /// Base path prefix for all Endurain API endpoints.
  ///
  /// Combined with the server origin to form full endpoint URLs:
  /// `<serverUrl><apiBasePath>/auth/login`.
  ///
  /// Exists here so a future API version bump changes one constant rather than
  /// every service that builds endpoint strings.
  final String apiBasePath;

  /// Whether the app permits connections to `http://` server URLs.
  ///
  /// Defaults to `true` to support self-hosted deployments on local networks.
  /// Set to `false` in managed or SaaS builds where plain-HTTP transport must
  /// be refused rather than warned about.
  ///
  /// The login flow checks this flag: when `false`, an `http://` server URL is
  /// rejected as a validation error; when `true` (default), the user receives
  /// a localized warning and can confirm before proceeding.
  final bool allowInsecureTransport;

  /// The current Endurain API version path prefix.
  static const String defaultApiBasePath = '/api/v1';

  /// Production-safe defaults — identical to the existing self-hosted behavior.
  static const AppConfig defaults = AppConfig();
}
