import 'package:endurain/core/services/api_client.dart';
import 'package:endurain/core/services/app_infrastructure.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/server_settings_service.dart';
import 'package:endurain/core/services/sso_service.dart';

/// Wires the authentication feature: session storage, password/MFA login, SSO,
/// public server-settings discovery, and the authenticated API client.
///
/// Depends only on [AppInfrastructure]; nothing in this module reaches into
/// another feature, so it can be reasoned about and tested in isolation.
class AuthModule {
  AuthModule(this._infra);

  final AppInfrastructure _infra;

  /// The durable, serialized auth session (tokens, origin, profile).
  late final AuthSessionStore session = AuthSessionStore(
    storage: _infra.secureStorage,
    config: _infra.config,
  );

  /// Password/MFA login, token refresh, and logout.
  late final AuthService service = AuthService(
    storage: _infra.secureStorage,
    sessionStore: session,
    config: _infra.config,
    endpoints: _infra.endpoints,
  );

  /// SSO/OAuth (PKCE) login against the server's identity providers.
  late final SsoService sso = SsoService(
    storage: _infra.secureStorage,
    sessionStore: session,
    config: _infra.config,
    endpoints: _infra.endpoints,
  );

  /// Public server-settings discovery (local-login/SSO availability).
  late final ServerSettingsService serverSettings = ServerSettingsService(
    storage: _infra.secureStorage,
    config: _infra.config,
    endpoints: _infra.endpoints,
  );

  /// Authenticated, token-refreshing multipart API client.
  late final ApiClient apiClient = ApiClient(
    storage: _infra.secureStorage,
    sessionStore: session,
    authService: service,
    config: _infra.config,
  );
}
