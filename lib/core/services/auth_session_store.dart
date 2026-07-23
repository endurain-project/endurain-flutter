import 'dart:convert';

import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/utils/id_generation.dart';
import 'package:endurain/core/utils/serial_task_queue.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';

class AuthSessionStore {
  AuthSessionStore({
    required SecureStorageService storage,
    AppConfig config = AppConfig.defaults,
  }) : _storage = storage,
       _config = config;

  final SecureStorageService _storage;
  final AppConfig _config;
  final SerialTaskQueue _queue = SerialTaskQueue();

  Future<AuthSession?> readSession() => _serialize(_readSessionUnlocked);

  Future<AuthSession?> _readSessionUnlocked() async {
    final raw = await _storage.getAuthSession();
    if (raw == null || raw.isEmpty) {
      return null;
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
      // Blobs written before the `accountId` field existed are upgraded in
      // place: `accountId` falls back to the legacy `profileId` value inside
      // `fromJson`, and a missing `revision` receives a fresh token.
      final needsMigration =
          decoded['accountId'] == null || decoded['revision'] == null;
      final session = AuthSession.fromJson(
        decoded,
        fallbackRevision: needsMigration ? connectionRevision() : null,
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

  Future<String?> getAccessToken() async => (await readSession())?.accessToken;

  Future<String?> getRefreshToken() async =>
      (await readSession())?.refreshToken;

  Future<void> saveLoginUsername(String username) {
    return _storage.setUsername(username);
  }

  Future<void> saveSession({
    required String origin,
    required String accessToken,
    required String refreshToken,
    required String sessionId,
    required String accountId,
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
        accountId: accountId,
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
        accountId: expected.accountId,
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
    required String accountId,
  }) {
    final session = AuthSession(
      accountId: accountId,
      revision: connectionRevision(),
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

  Future<T> _serialize<T>(Future<T> Function() action) => _queue.run(action);

  AuthSession _normalizeSession(AuthSession session) {
    final origin = ServerUrlResolver.normalize(session.origin, config: _config);
    final connectionKind = _config.isManagedOrigin(origin)
        ? ConnectionKind.managed
        : ConnectionKind.selfHosted;
    if (origin == session.origin && connectionKind == session.connectionKind) {
      return session;
    }
    return AuthSession(
      accountId: session.accountId,
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
