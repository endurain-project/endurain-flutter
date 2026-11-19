import 'package:endurain/app/app_infrastructure.dart';
import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/auth/auth_session_store.dart';
import 'package:endurain/core/auth/server_settings_service.dart';
import 'package:endurain/core/auth/sign_in_flow.dart';
import 'package:endurain/core/auth/sso_service.dart';
import 'package:endurain/core/network/api_client.dart';
import 'package:endurain/core/network/base_http_client.dart';

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

  /// The step-by-step sign-in (`next_step`) shared by password and SSO
  /// sign-ins: an SSO sign-in of an account with MFA continues at
  /// [AuthService.verifyMfa], so both services must hold the same pending
  /// state.
  late final SignInFlow signInFlow = SignInFlow(
    sessionStore: session,
    http: BaseHttpClient(),
    storage: _infra.secureStorage,
    endpoints: _infra.endpoints,
  );

  /// Password/MFA login, token refresh, and logout.
  late final AuthService service = AuthService(
    storage: _infra.secureStorage,
    sessionStore: session,
    config: _infra.config,
    endpoints: _infra.endpoints,
    signInFlow: signInFlow,
  );

  /// SSO/OAuth (PKCE) login against the server's identity providers.
  late final SsoService sso = SsoService(
    storage: _infra.secureStorage,
    sessionStore: session,
    config: _infra.config,
    endpoints: _infra.endpoints,
    signInFlow: signInFlow,
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
