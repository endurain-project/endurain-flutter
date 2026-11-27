import 'package:endurain/core/auth/auth_session_store.dart';
import 'package:endurain/core/auth/pkce_token_exchanger.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/network/api_response.dart';
import 'package:endurain/core/network/base_http_client.dart';
import 'package:endurain/core/utils/pkce_utils.dart';

/// What the sign-in needs from the user next.
enum SignInStep {
  /// The session is saved; the user is signed in.
  signedIn,

  /// A second-factor code is needed ([SignInFlow.verifyMfa]).
  mfa,

  /// An administrator set the password; a new one is needed
  /// ([SignInFlow.changePassword]).
  passwordChange,
}

/// The outcome of one sign-in step.
///
/// Carries only what the login UI needs. Issued tokens and challenges are never
/// returned here: tokens go to secure storage, challenges stay in
/// [SignInFlow].
class AuthResult {
  const AuthResult.signedIn()
    : step = SignInStep.signedIn,
      mfaMethods = const [];

  const AuthResult.mfa({this.mfaMethods = const []}) : step = SignInStep.mfa;

  const AuthResult.passwordChange()
    : step = SignInStep.passwordChange,
      mfaMethods = const [];

  final SignInStep step;

  /// The kinds of code the account can answer the MFA step with, such as
  /// `totp` and `backup_code`. An open set; empty when the server named none.
  final List<String> mfaMethods;
}

/// Runs an Endurain (v0.21+) mobile sign-in from its first request to the
/// saved session, by following the `next_step` of every answer.
///
/// `POST /auth/login`, `POST /auth/mfa/verify`, `POST /auth/password-change`
/// and the token exchange `POST /auth/sessions/{session_id}/tokens` each answer
/// one of:
/// - `mfa`: a second factor is needed; the `mfa_challenge` is kept here;
/// - `password_change`: a new password is needed; the challenge is kept here;
/// - `exchange`: a sign-in session to exchange with the PKCE verifier, done
///   here at once;
/// - `tokens`: the session, saved through [PkceTokenExchanger.saveTokens].
///
/// Any other value means the server is newer than this app: the sign-in is
/// abandoned with [AppErrorCode.signInStepUnsupported].
///
/// `AuthService` (password) and `SsoService` (provider callback) share one
/// instance, because an SSO sign-in of an account with MFA continues at
/// [verifyMfa]. The pending state lives in memory only and is bound to the
/// server the sign-in started on.
class SignInFlow {
  SignInFlow({
    required AuthSessionStore sessionStore,
    required BaseHttpClient http,
    required SecureStorageService storage,
    ApiEndpoints? endpoints,
    PkceTokenExchanger? exchanger,
  }) : _http = http,
       _storage = storage,
       _endpoints = endpoints ?? const ApiEndpoints(),
       _exchanger =
           exchanger ??
           PkceTokenExchanger(
             sessionStore: sessionStore,
             http: http,
             endpoints: endpoints,
           );

  final BaseHttpClient _http;
  final SecureStorageService _storage;
  final ApiEndpoints _endpoints;
  final PkceTokenExchanger _exchanger;

  /// A device id is 43 characters of the URL-safe base64 alphabet; anything
  /// else is neither stored nor sent.
  static final RegExp _deviceIdPattern = RegExp(r'^[A-Za-z0-9_-]{43}$');

  _PendingSignIn? _pending;

  /// Starts a password sign-in on [serverUrl] (already normalized), with a
  /// fresh PKCE pair whose challenge goes in the login form.
  Future<AuthResult> startPassword({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final pkce = PkceUtils.generatePkce();
    final pending = _pending = _PendingSignIn(
      serverUrl: serverUrl,
      verifier: pkce.verifier,
      username: username,
    );
    return _run(pending, fallbackCode: AppErrorCode.loginError, () async {
      final data = await _http.postJsonObject(
        Uri.parse('$serverUrl${_endpoints.tokenEndpoint}'),
        extraHeaders: {
          ApiConstants.contentTypeHeader:
              ApiConstants.contentTypeFormUrlEncoded,
          ...await _deviceIdHeader(serverUrl),
        },
        rawBody: {
          'username': username,
          'password': password,
          'code_challenge': pkce.challenge,
          'code_challenge_method': 'S256',
        },
        failureCode: AppErrorCode.loginFailed,
      );
      return _follow(
        pending,
        data,
        failureCode: AppErrorCode.tokenExchangeFailed,
      );
    });
  }

  /// Exchanges the sign-in session [sessionId] an SSO callback delivered, with
  /// the [verifier] of the PKCE pair the provider sign-in started with.
  Future<AuthResult> startExchange({
    required String serverUrl,
    required String sessionId,
    required String verifier,
    required AppErrorCode failureCode,
    required AppErrorCode fallbackCode,
  }) {
    final pending = _pending = _PendingSignIn(serverUrl: serverUrl);
    return _run(pending, fallbackCode: fallbackCode, () async {
      final data = await _exchanger.exchange(
        serverUrl: serverUrl,
        sessionId: sessionId,
        verifier: verifier,
        deviceId: await _deviceId(serverUrl),
        failureCode: failureCode,
      );
      return _follow(pending, data, failureCode: failureCode);
    });
  }

  /// Answers the pending MFA step with [code].
  ///
  /// A wrong code keeps the step (the server allows three tries); a dead
  /// challenge ends the sign-in with [AppErrorCode.mfaSessionMissing].
  Future<AuthResult> verifyMfa(String code) async {
    final pending = _pending;
    final challenge = pending?.challenge;
    if (pending == null || challenge is! _MfaChallenge) {
      throw const AppException(AppErrorCode.mfaSessionMissing);
    }
    return _runStep(
      pending,
      fallbackCode: AppErrorCode.mfaVerificationError,
      () async {
        final data = await _http.postJsonObject(
          Uri.parse('${pending.serverUrl}${_endpoints.mfaVerifyEndpoint}'),
          extraHeaders: await _deviceIdHeader(pending.serverUrl),
          jsonBody: {'mfa_challenge': challenge.value, 'mfa_code': code},
          failureCode: AppErrorCode.mfaVerificationFailed,
        );
        return _follow(
          pending,
          data,
          failureCode: AppErrorCode.tokenExchangeFailed,
        );
      },
    );
  }

  /// Answers the pending password-change step with [newPassword].
  ///
  /// A password the policy refuses keeps the step
  /// ([AppErrorCode.passwordChangeFailed] with the server's reason); a dead
  /// challenge ends the sign-in with [AppErrorCode.mfaSessionMissing].
  Future<AuthResult> changePassword(String newPassword) async {
    final pending = _pending;
    final challenge = pending?.challenge;
    if (pending == null || challenge is! _PasswordChangeChallenge) {
      throw const AppException(AppErrorCode.mfaSessionMissing);
    }
    return _runStep(
      pending,
      fallbackCode: AppErrorCode.passwordChangeFailed,
      () async {
        final data = await _http.postJsonObject(
          Uri.parse('${pending.serverUrl}${_endpoints.passwordChangeEndpoint}'),
          extraHeaders: await _deviceIdHeader(pending.serverUrl),
          jsonBody: {
            'password_change_challenge': challenge.value,
            'password': newPassword,
          },
          failureCode: AppErrorCode.passwordChangeFailed,
        );
        return _follow(
          pending,
          data,
          failureCode: AppErrorCode.tokenExchangeFailed,
        );
      },
    );
  }

  /// Abandons any pending sign-in.
  void cancel() {
    _pending = null;
  }

  /// Runs the first request of a sign-in; any failure abandons it.
  Future<AuthResult> _run(
    _PendingSignIn pending,
    Future<AuthResult> Function() action, {
    required AppErrorCode fallbackCode,
  }) async {
    try {
      return await action();
    } catch (error) {
      _clearIfCurrent(pending);
      if (error is AppException) {
        rethrow;
      }
      throw AppException(fallbackCode, cause: error);
    }
  }

  /// Runs the answer to a pending step. The step survives a failure the user
  /// can retry (a wrong code, a refused password, a network error), and ends
  /// on a `401`, which the server sends for a dead challenge.
  Future<AuthResult> _runStep(
    _PendingSignIn pending,
    Future<AuthResult> Function() action, {
    required AppErrorCode fallbackCode,
  }) async {
    try {
      return await action();
    } on AppException catch (error) {
      if (error.statusCode == 401) {
        _clearIfCurrent(pending);
        throw AppException(AppErrorCode.mfaSessionMissing, cause: error);
      }
      if (!pending.retryable) {
        _clearIfCurrent(pending);
      }
      rethrow;
    } catch (error) {
      if (!pending.retryable) {
        _clearIfCurrent(pending);
      }
      throw AppException(fallbackCode, cause: error);
    }
  }

  Future<AuthResult> _follow(
    _PendingSignIn pending,
    Map<String, dynamic> data, {
    required AppErrorCode failureCode,
  }) async {
    if (!identical(_pending, pending)) {
      // A newer sign-in replaced this one while its request was in flight.
      throw const AppException(AppErrorCode.mfaSessionMissing);
    }
    switch (data['next_step']) {
      case 'mfa':
        pending.challenge = _MfaChallenge(
          ApiResponse.requiredString(data, 'mfa_challenge'),
        );
        return AuthResult.mfa(mfaMethods: _stringList(data['methods']));
      case 'password_change':
        pending.challenge = _PasswordChangeChallenge(
          ApiResponse.requiredString(data, 'password_change_challenge'),
        );
        return const AuthResult.passwordChange();
      case 'exchange':
        final sessionId = ApiResponse.requiredString(data, 'session_id');
        await _rememberDeviceId(pending.serverUrl, data['device_id']);
        final verifier = pending.verifier;
        if (verifier == null) {
          // Only a password sign-in holds a verifier, and it is used once.
          throw const AppException(
            AppErrorCode.pkceVerifierMissingRestartLogin,
          );
        }
        pending
          ..verifier = null
          ..challenge = null
          ..retryable = false;
        final next = await _exchanger.exchange(
          serverUrl: pending.serverUrl,
          sessionId: sessionId,
          verifier: verifier,
          deviceId: await _deviceId(pending.serverUrl),
          failureCode: failureCode,
        );
        return _follow(pending, next, failureCode: failureCode);
      case 'tokens':
        pending.retryable = false;
        await _exchanger.saveTokens(
          serverUrl: pending.serverUrl,
          body: data,
          username: pending.username,
          failureCode: failureCode,
        );
        await _rememberDeviceId(pending.serverUrl, data['device_id']);
        _clearIfCurrent(pending);
        return const AuthResult.signedIn();
      default:
        _clearIfCurrent(pending);
        throw const AppException(AppErrorCode.signInStepUnsupported);
    }
  }

  void _clearIfCurrent(_PendingSignIn pending) {
    if (identical(_pending, pending)) {
      _pending = null;
    }
  }

  Future<String?> _deviceId(String serverUrl) async {
    try {
      final id = await _storage.getDeviceId(serverUrl);
      return id != null && _deviceIdPattern.hasMatch(id) ? id : null;
    } catch (_) {
      // Without the id the sign-in still works; the server mints a new one.
      return null;
    }
  }

  Future<Map<String, String>> _deviceIdHeader(String serverUrl) async {
    final id = await _deviceId(serverUrl);
    return {ApiConstants.deviceIdHeader: ?id};
  }

  Future<void> _rememberDeviceId(String serverUrl, Object? value) async {
    if (value is! String || !_deviceIdPattern.hasMatch(value)) {
      return;
    }
    try {
      if (await _storage.getDeviceId(serverUrl) != value) {
        await _storage.setDeviceId(serverUrl, value);
      }
    } catch (_) {
      // Best effort: a lost id only makes the next sign-in a new device.
    }
  }

  static List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}

class _PendingSignIn {
  _PendingSignIn({required this.serverUrl, this.verifier, this.username});

  final String serverUrl;

  /// The PKCE verifier of a password sign-in, until its session is exchanged.
  String? verifier;
  final String? username;
  _Challenge? challenge;

  /// Whether a failed step answer can be retried. Turns false once the
  /// sign-in moves past its challenges (exchange or tokens), where a failure
  /// leaves nothing to retry.
  bool retryable = true;
}

sealed class _Challenge {
  const _Challenge(this.value);
  final String value;
}

class _MfaChallenge extends _Challenge {
  const _MfaChallenge(super.value);
}

class _PasswordChangeChallenge extends _Challenge {
  const _PasswordChangeChallenge(super.value);
}
