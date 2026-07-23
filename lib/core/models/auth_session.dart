import 'package:endurain/core/utils/connection_identity.dart';

enum ConnectionKind {
  selfHosted,
  managed;

  static ConnectionKind fromJson(Object? value) {
    return value == managed.name ? managed : selfHosted;
  }
}

class ConnectionProfile {
  const ConnectionProfile({
    required this.id,
    required this.origin,
    required this.kind,
  });

  /// The globally-unique, origin-qualified profile id (see
  /// [ConnectionIdentity.profileId]). This is the value every per-connection
  /// store scopes on; it is safe across self-hosted and managed origins that
  /// may reuse the same server account id.
  final String id;
  final String origin;
  final ConnectionKind kind;
}

/// The authenticated connection currently active in the app.
///
/// Endurain intentionally supports one active connection at a time. Keeping its
/// origin and credentials in one value prevents a server selected during a new
/// login flow from being mixed with credentials issued by another server.
///
/// ## Two identity tokens — [profileId] vs [revision]
///
/// These look similar but answer different questions and must not be conflated:
///
/// - [profileId] — *"which account, on which server, is this?"* A **stable**,
///   globally-unique identity derived from [origin] + [accountId] (see
///   [ConnectionIdentity]). It is identical across logout/login cycles to the
///   same account and is the key every per-connection store scopes on (activity
///   records, health-import provenance, health settings). It never changes for
///   a given account on a given server.
///
/// - [revision] — *"is this the exact stored session I last read?"* An
///   **ephemeral**, random token minted on every session write. It exists only
///   for optimistic concurrency: single-flight token refresh keys on it, and
///   `replaceSessionIfCurrent` / `clearIfCurrent` use it to detect that the
///   stored session was swapped out (e.g. a re-login) between a read and a
///   write. Two sessions for the *same* account share a [profileId] but get a
///   fresh [revision] on every write.
class AuthSession {
  const AuthSession({
    required this.accountId,
    required this.revision,
    required this.origin,
    required this.connectionKind,
    required this.accessToken,
    required this.refreshToken,
    required this.sessionId,
    required this.accessTokenExpiresAt,
    this.username,
  });

  /// Raw server-assigned account id (e.g. `"1"`). Unique only within [origin];
  /// combine with [origin] via [profileId] for a globally-unique identity.
  final String accountId;
  final String revision;
  final String origin;
  final ConnectionKind connectionKind;
  final String accessToken;
  final String refreshToken;
  final String sessionId;
  final DateTime accessTokenExpiresAt;
  final String? username;

  /// Globally-unique, origin-qualified identity for this connection.
  ///
  /// Derived (never stored on its own) so it can never drift from [origin] /
  /// [accountId]. This is what [ConnectionProfile.id] exposes and what stores
  /// persist as the connection scope.
  String get profileId =>
      ConnectionIdentity.profileId(origin: origin, accountId: accountId);

  ConnectionProfile get profile =>
      ConnectionProfile(id: profileId, origin: origin, kind: connectionKind);

  Map<String, Object?> toJson() {
    return {
      'accountId': accountId,
      'revision': revision,
      'origin': origin,
      'connectionKind': connectionKind.name,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'sessionId': sessionId,
      'accessTokenExpiresAt': accessTokenExpiresAt.toUtc().toIso8601String(),
      if (username != null) 'username': username,
    };
  }

  /// Rebuilds a session from stored JSON.
  ///
  /// [fallbackAccountId] / [fallbackRevision] cover blobs written before those
  /// fields existed: older sessions stored the raw account id under the
  /// `profileId` key, so that value is adopted as [accountId] when present.
  factory AuthSession.fromJson(
    Map<String, Object?> json, {
    String? fallbackAccountId,
    String? fallbackRevision,
  }) {
    // Pre-`accountId` blobs persisted the raw account id under `profileId`.
    final accountId =
        json['accountId'] ?? json['profileId'] ?? fallbackAccountId;
    final revision = json['revision'] ?? fallbackRevision;
    final origin = json['origin'];
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final sessionId = json['sessionId'];
    final expiresAt = json['accessTokenExpiresAt'];
    final username = json['username'];
    if (accountId is! String ||
        accountId.isEmpty ||
        revision is! String ||
        revision.isEmpty ||
        origin is! String ||
        accessToken is! String ||
        refreshToken is! String ||
        sessionId is! String ||
        expiresAt is! String ||
        (username != null && username is! String)) {
      throw const FormatException('Invalid stored authentication session.');
    }
    final parsedExpiry = DateTime.tryParse(expiresAt);
    if (parsedExpiry == null) {
      throw const FormatException('Invalid authentication session expiry.');
    }
    return AuthSession(
      accountId: accountId,
      revision: revision,
      origin: origin,
      connectionKind: ConnectionKind.fromJson(json['connectionKind']),
      accessToken: accessToken,
      refreshToken: refreshToken,
      sessionId: sessionId,
      accessTokenExpiresAt: parsedExpiry.toUtc(),
      username: username as String?,
    );
  }
}
