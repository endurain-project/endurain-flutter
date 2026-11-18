import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/utils/connection_identity.dart';
import 'package:endurain/core/utils/serial_task_queue.dart';
import 'package:endurain/features/account_migration/repositories/legacy_profile_alias_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/health/repositories/health_import_repository.dart';
import 'package:endurain/features/health/repositories/health_sync_settings_repository.dart';

/// A pre-v0.21 profile whose local data may belong to the account that just
/// signed in.
class LegacyProfileCandidate {
  const LegacyProfileCandidate({
    required this.legacyProfileId,
    required this.profile,
    this.username,
  });

  /// The `<origin>#<integer>` profile id the data is stored under.
  final String legacyProfileId;

  /// The profile of the account that just signed in.
  final ConnectionProfile profile;

  /// The username of that sign-in, for the confirmation prompt. `null` after
  /// an SSO sign-in.
  final String? username;
}

/// Asks the user whether a [LegacyProfileCandidate]'s data is theirs.
///
/// Returns `true` to move it to the new account, `false` when it belongs to
/// someone else, and `null` when the user did not answer (asked again at the
/// next sign-in).
typedef ConfirmLegacyProfile = Future<bool?> Function(
  LegacyProfileCandidate candidate,
);

/// Moves the local data of a pre-v0.21 account onto the profile id it has
/// after the server upgrade.
///
/// Endurain v0.21 replaced every integer account id with a UUID and offers no
/// mapping between the two, so `<origin>#42` and `<origin>#<uuid>` look like
/// different accounts. Without this service, activities waiting to upload are
/// never drained (the upload queue only takes the active profile's records),
/// and health sync imports every workout again under new idempotency keys,
/// which duplicates them on the server.
///
/// The flow:
/// 1. [captureLegacyHint] runs at launch, before anything can clear the stored
///    session, and remembers its legacy profile id and a username hash.
/// 2. [resolveAfterSignIn] runs after a sign-in on a v0.21 server. A legacy
///    profile on the same origin whose username matches is adopted silently;
///    one with a different known username is left alone; any other is offered
///    to the user through [ConfirmLegacyProfile].
/// 3. [reapply] runs before every upload-queue drain and moves data that
///    reached the legacy id after the adoption (a recording that was in
///    progress across the app update), or that a crash left behind.
///
/// Records keep their ids and idempotency keys, so an upload whose `202` was
/// lost before the upgrade still de-duplicates on the server.
class LegacyProfileAdoptionService {
  LegacyProfileAdoptionService({
    required Future<AuthSession?> Function() readSession,
    required LegacyProfileAliasRepository aliases,
    required LocalActivityRepository localActivities,
    required HealthImportRepository healthImports,
    required HealthSyncSettingsRepository healthSettings,
    DiagnosticsRecorder? diagnostics,
    DateTime Function()? now,
  }) : _readSession = readSession,
       _aliases = aliases,
       _localActivities = localActivities,
       _healthImports = healthImports,
       _healthSettings = healthSettings,
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder(),
       _now = now ?? DateTime.now;

  final Future<AuthSession?> Function() _readSession;
  final LegacyProfileAliasRepository _aliases;
  final LocalActivityRepository _localActivities;
  final HealthImportRepository _healthImports;
  final HealthSyncSettingsRepository _healthSettings;
  final DiagnosticsRecorder _diagnostics;
  final DateTime Function() _now;

  /// Serializes every read-modify-write of the aliases and every data move.
  /// The confirmation prompt is shown outside it, so an unanswered prompt
  /// never holds up [reapply] and the upload queue.
  final SerialTaskQueue _queue = SerialTaskQueue();

  /// Remembers the stored session's profile id when it is a legacy one.
  ///
  /// Call at launch, before the first network request: against a v0.21 server
  /// the stored tokens are refused and the session is cleared, after which
  /// the username that signed in is lost. Never throws.
  Future<void> captureLegacyHint() async {
    try {
      await _queue.run(() async {
        final session = await _readSession();
        if (session == null ||
            !ConnectionIdentity.isLegacyAccountId(session.accountId)) {
          return;
        }
        final aliases = await _aliases.load();
        final profileId = session.profileId;
        final hash = _usernameHash(session.username);
        if (aliases.hints.containsKey(profileId) &&
            (hash == null || aliases.hints[profileId] == hash)) {
          return;
        }
        await _aliases.save(
          aliases.copyWith(hints: {...aliases.hints, profileId: hash}),
        );
      });
    } catch (error) {
      _recordFailure('capture', error);
    }
  }

  /// Offers the data of the legacy profiles on the signed-in origin to the
  /// account that just signed in, adopting at most one. Never throws.
  Future<void> resolveAfterSignIn({
    required ConfirmLegacyProfile confirm,
  }) async {
    try {
      final candidates = await _queue.run(_candidatesForCurrentSession);
      for (final (:candidate, :match) in candidates) {
        switch (match) {
          case _HintMatch.sameUser:
            await _adopt(candidate);
            return;
          case _HintMatch.otherUser:
            continue;
          case _HintMatch.unknown:
            final answer = await confirm(candidate);
            if (answer == null) {
              return;
            }
            if (answer) {
              await _adopt(candidate);
              return;
            }
            await _decline(candidate);
        }
      }
    } catch (error) {
      _recordFailure('resolve', error);
    }
  }

  /// Moves any data still stored under a legacy profile id adopted by
  /// [profile]. Idempotent and cheap when there is nothing to move. Never
  /// throws.
  Future<void> reapply(ConnectionProfile profile) async {
    try {
      await _queue.run(() async {
        final aliases = await _aliases.load();
        for (final MapEntry(key: legacyId, value: target)
            in aliases.adopted.entries) {
          if (target == profile.id) {
            await _moveData(legacyId, profile);
          }
        }
      });
    } catch (error) {
      _recordFailure('reapply', error);
    }
  }

  Future<List<({LegacyProfileCandidate candidate, _HintMatch match})>>
  _candidatesForCurrentSession() async {
    final session = await _readSession();
    if (session == null ||
        ConnectionIdentity.isLegacyAccountId(session.accountId)) {
      // Signed out, or signed in to a pre-v0.21 server: nothing to adopt.
      return const [];
    }
    final profile = session.profile;
    final aliases = await _aliases.load();
    if (aliases.adopted.containsValue(profile.id)) {
      // One account has one legacy id; this one already adopted its own.
      return const [];
    }

    final legacyIds =
        <String>{
              ...await _localActivities.listConnectionProfileIds(
                origin: profile.origin,
              ),
              ...await _healthImports.listProfileIds(),
              ...aliases.hints.keys,
            }
            .where(
              (id) => ConnectionIdentity.isLegacyProfileIdFor(
                id,
                origin: profile.origin,
              ),
            )
            .where((id) => !aliases.adopted.containsKey(id))
            .where(
              (id) => !(aliases.declined[id]?.contains(profile.id) ?? false),
            )
            .toList()
          ..sort();

    final usernameHash = _usernameHash(session.username);
    final candidates = [
      for (final legacyId in legacyIds)
        (
          candidate: LegacyProfileCandidate(
            legacyProfileId: legacyId,
            profile: profile,
            username: session.username,
          ),
          match: _matchHint(aliases.hints[legacyId], usernameHash),
        ),
    ];
    // Try the legacy id whose username matches first.
    candidates.sort(
      (a, b) => (a.match == _HintMatch.sameUser ? 0 : 1).compareTo(
        b.match == _HintMatch.sameUser ? 0 : 1,
      ),
    );
    return candidates;
  }

  /// Usernames are unique and case-insensitive on one Endurain server, so a
  /// hint recorded on the same origin with the same username is the same
  /// account, and one with a different username is someone else's (unless
  /// the user renamed their account, which the prompt cannot resolve either).
  static _HintMatch _matchHint(String? hintHash, String? usernameHash) {
    if (hintHash == null || usernameHash == null) {
      return _HintMatch.unknown;
    }
    return hintHash == usernameHash
        ? _HintMatch.sameUser
        : _HintMatch.otherUser;
  }

  Future<void> _adopt(LegacyProfileCandidate candidate) {
    return _queue.run(() async {
      final aliases = await _aliases.load();
      final existing = aliases.adopted[candidate.legacyProfileId];
      if (existing != null && existing != candidate.profile.id) {
        return;
      }
      // Record the decision first: [reapply] finishes a move a crash cut
      // short, but only for a decision that was saved.
      await _aliases.save(
        aliases.copyWith(
          adopted: {
            ...aliases.adopted,
            candidate.legacyProfileId: candidate.profile.id,
          },
        ),
      );
      await _moveData(candidate.legacyProfileId, candidate.profile);
      _diagnostics.recordBreadcrumbSync(DiagnosticsEvents.legacyProfileAdopted);
    });
  }

  Future<void> _decline(LegacyProfileCandidate candidate) {
    return _queue.run(() async {
      final aliases = await _aliases.load();
      final legacyId = candidate.legacyProfileId;
      await _aliases.save(
        aliases.copyWith(
          declined: {
            ...aliases.declined,
            legacyId: {...?aliases.declined[legacyId], candidate.profile.id},
          },
        ),
      );
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.legacyProfileDeclined,
      );
    });
  }

  Future<void> _moveData(String legacyId, ConnectionProfile profile) async {
    // Activities first: health provenance is adopted only for a local activity
    // that already belongs to the active profile.
    await _localActivities.rebindConnectionProfile(
      origin: profile.origin,
      fromProfileId: legacyId,
      toProfileId: profile.id,
      updatedAt: _now().toUtc(),
    );
    await _healthImports.reassignProfile(
      fromProfileId: legacyId,
      toProfileId: profile.id,
    );
    await _healthSettings.moveProfile(
      fromProfileId: legacyId,
      toProfileId: profile.id,
    );
  }

  static String? _usernameHash(String? username) {
    final normalized = username?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  void _recordFailure(String step, Object error) {
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.legacyProfileMigrationFailed,
      details: {'step': step, 'type': error.runtimeType.toString()},
    );
  }
}

enum _HintMatch { sameUser, otherUser, unknown }
