import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';

class AuthSessionStore {
  AuthSessionStore({
    required SecureStorageService storage,
    AppConfig config = AppConfig.defaults,
  }) : _storage = storage,
       _config = config;

  final SecureStorageService _storage;
  final AppConfig _config;
  Future<void> _mutationTail = Future<void>.value();

  Future<AuthSession?> readSession() => _serialize(_readSessionUnlocked);

  Future<AuthSession?> _readSessionUnlocked() async {
    final raw = await _storage.getAuthSession();
    if (raw == null || raw.isEmpty) {
      if (await _storage.isAuthSessionAuthoritative()) {
        return null;
      }
      return _readLegacySession();
    }
    try {
      final decodedValue = jsonDecode(raw);
      if (decodedValue is! Map) {
        throw const FormatException('Stored session must be an object.');
      }
      final decoded = <String, Object?>{};
      for (final entry in decodedValue.entries) {
        if (entry.key is! String) {
          throw const FormatException('Stored session has an invalid key.');
        }
        decoded[entry.key as String] = entry.value;
      }
      final needsMigration =
          decoded['profileId'] == null || decoded['revision'] == null;
      final session = AuthSession.fromJson(
        decoded,
        fallbackProfileId: needsMigration ? _newRevision() : null,
        fallbackRevision: needsMigration ? _newRevision() : null,
      );
      final normalized = _normalizeSession(session);
      if (needsMigration || normalized.origin != session.origin) {
        await _writeCanonicalSession(normalized);
      }
      return normalized;
    } on FormatException catch (_) {
      await _clearUnlocked();
      return null;
    }
  }

  Future<String?> getAuthenticatedOrigin() async =>
      (await readSession())?.origin;

  Future<ConnectionProfile?> getConnectionProfile() async =>
      (await readSession())?.profile;

  Future<String?> getLastServerUrl() => _storage.getServerUrl();

  @Deprecated('Use getAuthenticatedOrigin or getLastServerUrl explicitly.')
  Future<String?> getServerUrl() => getLastServerUrl();

  Future<String?> getAccessToken() async => (await readSession())?.accessToken;

  Future<String?> getRefreshToken() async =>
      (await readSession())?.refreshToken;

  Future<bool> isAccessTokenExpiringSoon({
    Duration threshold = const Duration(minutes: 2),
  }) async {
    final session = await readSession();
    if (session == null) {
      return false;
    }
    return DateTime.now()
        .toUtc()
        .add(threshold)
        .isAfter(session.accessTokenExpiresAt);
  }

  Future<void> saveLoginUsername(String username) {
    return _storage.setUsername(username);
  }

  Future<void> saveSession({
    required String origin,
    required String accessToken,
    required String refreshToken,
    required String sessionId,
    String? username,
    required int expiresInSeconds,
  }) async {
    await _mutate(() async {
      final normalizedOrigin = ServerUrlResolver.normalize(
        origin,
        config: _config,
      );
      final session = _buildSession(
        origin: normalizedOrigin,
        accessToken: accessToken,
        refreshToken: refreshToken,
        sessionId: sessionId,
        username: username,
        expiresInSeconds: expiresInSeconds,
        profileId: _newRevision(),
      );
      await _writeCanonicalSession(session);
    });
  }

  Future<bool> replaceSessionIfCurrent({
    required AuthSession expected,
    required String accessToken,
    required String refreshToken,
    required String sessionId,
    required int expiresInSeconds,
  }) async {
    var replaced = false;
    await _mutate(() async {
      final current = await _readSessionUnlocked();
      if (current?.revision != expected.revision) {
        return;
      }
      final replacement = _buildSession(
        origin: expected.origin,
        accessToken: accessToken,
        refreshToken: refreshToken,
        sessionId: sessionId,
        username: expected.username,
        expiresInSeconds: expiresInSeconds,
        connectionKind: expected.connectionKind,
        profileId: expected.profileId,
      );
      await _writeCanonicalSession(replacement);
      replaced = true;
    });
    return replaced;
  }

  Future<bool> clearIfCurrent(AuthSession expected) async {
    var cleared = false;
    await _mutate(() async {
      final current = await _readSessionUnlocked();
      if (current?.revision != expected.revision) {
        return;
      }
      await _clearUnlocked();
      cleared = true;
    });
    return cleared;
  }

  Future<bool> clearIfProfileCurrent(AuthSession expected) async {
    var cleared = false;
    await _mutate(() async {
      final current = await _readSessionUnlocked();
      if (current?.profileId != expected.profileId) {
        return;
      }
      await _clearUnlocked();
      cleared = true;
    });
    return cleared;
  }

  AuthSession _buildSession({
    required String origin,
    required String accessToken,
    required String refreshToken,
    required String sessionId,
    required int expiresInSeconds,
    String? username,
    ConnectionKind? connectionKind,
    required String profileId,
  }) {
    final session = AuthSession(
      profileId: profileId,
      revision: _newRevision(),
      origin: origin,
      connectionKind:
          connectionKind ??
          (_config.isManagedOrigin(origin)
              ? ConnectionKind.managed
              : ConnectionKind.selfHosted),
      accessToken: accessToken,
      refreshToken: refreshToken,
      sessionId: sessionId,
      accessTokenExpiresAt: DateTime.now().toUtc().add(
        Duration(seconds: expiresInSeconds),
      ),
      username: username,
    );
    return session;
  }

  Future<void> _writeCanonicalSession(AuthSession session) async {
    await _storage.setServerUrl(session.origin);
    await _storage.setAuthSession(jsonEncode(session.toJson()));
    await _storage.markAuthSessionAuthoritative();
    await _storage.clearLegacyAuthTokens();
    if (session.username != null) {
      await _storage.setUsername(session.username!);
    }
  }

  Future<void> clear() => _mutate(_clearUnlocked);

  Future<void> _clearUnlocked() => _storage.clearAuthTokens();

  Future<void> _mutate(Future<void> Function() action) {
    return _serialize(() async {
      await action();
    });
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _mutationTail = _mutationTail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<AuthSession?> _readLegacySession() async {
    final origin = await _storage.getServerUrl();
    final accessToken = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();
    final sessionId = await _storage.getSessionId();
    final expiresAt = await _storage.getAccessTokenExpiresAt();
    if (origin == null ||
        accessToken == null ||
        refreshToken == null ||
        sessionId == null ||
        expiresAt == null) {
      return null;
    }
    final session = AuthSession(
      profileId: _newRevision(),
      revision: _newRevision(),
      origin: ServerUrlResolver.normalize(origin, config: _config),
      connectionKind: _config.isManagedOrigin(origin)
          ? ConnectionKind.managed
          : ConnectionKind.selfHosted,
      accessToken: accessToken,
      refreshToken: refreshToken,
      sessionId: sessionId,
      accessTokenExpiresAt: expiresAt.toUtc(),
      username: await _storage.getUsername(),
    );
    await _writeCanonicalSession(session);
    return session;
  }

  String _newRevision() {
    final random = Random.secure().nextInt(1 << 32);
    return '${DateTime.now().toUtc().microsecondsSinceEpoch}-$random';
  }

  AuthSession _normalizeSession(AuthSession session) {
    final origin = ServerUrlResolver.normalize(session.origin, config: _config);
    final connectionKind = _config.isManagedOrigin(origin)
        ? ConnectionKind.managed
        : ConnectionKind.selfHosted;
    if (origin == session.origin && connectionKind == session.connectionKind) {
      return session;
    }
    return AuthSession(
      profileId: session.profileId,
      revision: session.revision,
      origin: origin,
      connectionKind: connectionKind,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      sessionId: session.sessionId,
      accessTokenExpiresAt: session.accessTokenExpiresAt,
      username: session.username,
    );
  }
}
