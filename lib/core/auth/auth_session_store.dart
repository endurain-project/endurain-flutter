import 'dart:convert';

import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/utils/id_generation.dart';
import 'package:endurain/core/utils/serial_task_queue.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';

/// Outcome of [AuthSessionStore.replaceSessionIfCurrent].
final class SessionReplacement {
  const SessionReplacement._({required this.replaced, this.persistError});

  /// The expected session was no longer current; nothing changed.
  static const superseded = SessionReplacement._(replaced: false);

  /// The replacement is the current session and is stored.
  static const stored = SessionReplacement._(replaced: true);

  /// Whether the replacement became the current session.
  final bool replaced;

  /// Set when secure storage rejected the replacement: it is the current
  /// session, but held in memory only until a later store operation manages
  /// to write it (see [AuthSessionStore.replaceSessionIfCurrent]).
  final Object? persistError;
}

class AuthSessionStore {
  AuthSessionStore({
    required SecureStorageService storage,
    AppConfig config = AppConfig.defaults,
  }) : _storage = storage,
       _config = config;

  final SecureStorageService _storage;
  final AppConfig _config;
  final SerialTaskQueue _queue = SerialTaskQueue();

  /// A refreshed session that secure storage refused to store, kept as the
  /// current session until a write succeeds. Only accessed on [_queue].
  ///
  /// The server rotates the refresh token on every refresh, so the stored
  /// session it replaced is already dead; this one is the only usable
  /// credential. While it is set every read of the session returns it and
  /// first retries the write. It is never persisted any other way: if the
  /// process ends before a write succeeds the new tokens are lost, the stored
  /// session's refresh is rejected and the user signs in again.
  AuthSession? _pendingSession;

  Future<AuthSession?> readSession() => _serialize(_readSessionUnlocked);

  Future<AuthSession?> _readSessionUnlocked() async {
    final pending = _pendingSession;
    if (pending != null) {
      await _tryPersistPending(pending);
      return pending;
    }
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
      // An explicit sign-in replaces whatever session was current, including
      // one still waiting to be stored.
      _pendingSession = null;
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
      await _writeSignInSession(session);
    });
  }

  /// Writes the session of an explicit sign-in, recovering a store that
  /// rejects the write with the least destructive step that works:
  ///
  /// 1. retry once, for a transient platform failure;
  /// 2. delete the auth keys only and write again, for a damaged auth entry;
  /// 3. reset the whole store and write again. Reached only when the store
  ///    rejects writes even with the auth keys gone (e.g. an invalidated
  ///    Android Keystore key), in which case no other value is readable
  ///    either, so the device ids and per-profile markers it removes are
  ///    already lost. Without it the user could not sign in until reinstall.
  Future<void> _writeSignInSession(AuthSession session) async {
    if (await _tryWrite(() => _writeCanonicalSession(session))) return;
    if (await _tryWrite(() => _writeCanonicalSession(session))) return;
    final authKeysCleared = await _tryWrite(_storage.clearAuthTokens);
    if (authKeysCleared &&
        await _tryWrite(() => _writeCanonicalSession(session))) {
      return;
    }
    await _storage.resetAll();
    await _writeCanonicalSession(session);
  }

  /// Runs [write], returning `false` when secure storage rejected it. Other
  /// failures propagate.
  static Future<bool> _tryWrite(Future<void> Function() write) async {
    try {
      await write();
      return true;
    } on AppException catch (error) {
      if (error.code != AppErrorCode.secureStorageWriteFailed &&
          error.code != AppErrorCode.secureStorageDeleteFailed) {
        rethrow;
      }
      return false;
    }
  }

  /// Replaces the session with refreshed tokens when [expected] is still the
  /// current session.
  ///
  /// When secure storage rejects the write the replacement still becomes the
  /// current session, in memory only, and the result carries the error: the
  /// server has already rotated the refresh token, so keeping [expected]
  /// would only defer a sign-out. Every later read of the session returns the
  /// replacement and retries the write; [clear], a matching [clearIfCurrent]
  /// or [clearIfProfileCurrent], and a sign-in ([saveSession]) discard it.
  /// Revision checks see it like a stored session.
  Future<SessionReplacement> replaceSessionIfCurrent({
    required AuthSession expected,
    required String accessToken,
    required String refreshToken,
    required String sessionId,
    required int expiresInSeconds,
  }) {
    return _serialize(() async {
      final current = await _readSessionUnlocked();
      if (current?.revision != expected.revision) {
        return SessionReplacement.superseded;
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
      // Only the session blob changes on a refresh: the origin and username
      // are the expected session's, and legacy keys were purged when it was
      // written. Skipping those writes keeps a refresh from failing on them.
      try {
        await _storage.setAuthSession(jsonEncode(replacement.toJson()));
      } on AppException catch (error) {
        if (error.code != AppErrorCode.secureStorageWriteFailed) rethrow;
        _pendingSession = replacement;
        return SessionReplacement._(replaced: true, persistError: error);
      }
      _pendingSession = null;
      return SessionReplacement.stored;
    });
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

  /// Writes [pending], the session held in memory only, and drops it from
  /// memory once stored. A rejected write keeps it pending for the next try.
  Future<void> _tryPersistPending(AuthSession pending) async {
    final stored = await _tryWrite(
      () => _storage.setAuthSession(jsonEncode(pending.toJson())),
    );
    if (stored && identical(_pendingSession, pending)) {
      _pendingSession = null;
    }
  }

  Future<void> _writeCanonicalSession(AuthSession session) async {
    await _storage.setServerUrl(session.origin);
    await _storage.setAuthSession(jsonEncode(session.toJson()));
    // The session is stored at this point. Purging pre-v2 keys and keeping
    // the login-form username are housekeeping: a failure there must not fail
    // the write, and both are retried at the next canonical write.
    await _tryWrite(_storage.clearLegacyAuthTokens);
    final username = session.username;
    if (username != null) {
      await _tryWrite(() => _storage.setUsername(username));
    }
  }

  Future<void> clear() => _mutate(_clearUnlocked);

  /// Discards a session still waiting to be stored before deleting the stored
  /// one, so even a failed delete never leaves it current.
  Future<void> _clearUnlocked() {
    _pendingSession = null;
    return _storage.clearAuthTokens();
  }

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
