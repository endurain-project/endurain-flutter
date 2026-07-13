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

  final String id;
  final String origin;
  final ConnectionKind kind;
}

/// The authenticated connection currently active in the app.
///
/// Endurain intentionally supports one active connection at a time. Keeping
/// its origin and credentials in one value prevents a server selected during a
/// new login flow from being mixed with credentials issued by another server.
class AuthSession {
  const AuthSession({
    required this.profileId,
    required this.revision,
    required this.origin,
    required this.connectionKind,
    required this.accessToken,
    required this.refreshToken,
    required this.sessionId,
    required this.accessTokenExpiresAt,
    this.username,
  });

  final String profileId;
  final String revision;
  final String origin;
  final ConnectionKind connectionKind;
  final String accessToken;
  final String refreshToken;
  final String sessionId;
  final DateTime accessTokenExpiresAt;
  final String? username;

  ConnectionProfile get profile =>
      ConnectionProfile(id: profileId, origin: origin, kind: connectionKind);

  Map<String, Object?> toJson() {
    return {
      'profileId': profileId,
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

  factory AuthSession.fromJson(
    Map<String, Object?> json, {
    String? fallbackProfileId,
    String? fallbackRevision,
  }) {
    final profileId = json['profileId'] ?? fallbackProfileId;
    final revision = json['revision'] ?? fallbackRevision;
    final origin = json['origin'];
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final sessionId = json['sessionId'];
    final expiresAt = json['accessTokenExpiresAt'];
    final username = json['username'];
    if (profileId is! String ||
        profileId.isEmpty ||
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
      profileId: profileId,
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
