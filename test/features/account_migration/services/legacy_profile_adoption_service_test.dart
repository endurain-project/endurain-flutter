import 'dart:io';

import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/features/account_migration/repositories/legacy_profile_alias_repository.dart';
import 'package:endurain/features/account_migration/services/legacy_profile_adoption_service.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/health/repositories/health_import_repository.dart';
import 'package:endurain/features/health/repositories/health_sync_settings_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';
import '../../../helpers/sqlite_local_activity_repository.dart';
import '../../health/fakes/fake_health_import_store.dart';

const _origin = 'https://endurain.example';
const _otherOrigin = 'https://other.example';
const _uuid = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
const _legacy = '$_origin#42';
const _legacyOther = '$_origin#7';
const _current = '$_origin#$_uuid';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalActivityRepository activities;
  late HealthImportRepository healthImports;
  late HealthSyncSettingsRepository healthSettings;
  late LegacyProfileAliasRepository aliases;
  late AuthSession? session;
  late LegacyProfileAdoptionService service;
  late List<LegacyProfileCandidate> asked;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    tempDir = await Directory.systemTemp.createTemp('legacy_adoption_test');
    activities = createTestLocalActivityRepository(tempDir);
    healthImports = HealthImportRepository(store: FakeHealthImportStore());
    healthSettings = HealthSyncSettingsRepository(
      preferences: FakePreferencesStore(),
      storage: SecureStorageService(),
    );
    aliases = LegacyProfileAliasRepository(preferences: FakePreferencesStore());
    session = null;
    asked = [];
    service = LegacyProfileAdoptionService(
      readSession: () async => session,
      aliases: aliases,
      localActivities: activities,
      healthImports: healthImports,
      healthSettings: healthSettings,
      now: () => DateTime.utc(2026, 11, 17, 8),
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  ConfirmLegacyProfile answer(bool? value) => (candidate) async {
    asked.add(candidate);
    return value;
  };

  Future<void> seedLegacyData(String profileId, {String id = 'run-1'}) async {
    await activities.upsert(_record(id, profileId));
    await healthImports.markImported(
      profileId: profileId,
      sourceId: 'hk-$id',
      localActivityId: id,
    );
    await healthSettings.setConnected(profileId, true);
    await healthSettings.setAutoSyncEnabled(profileId, true);
  }

  Future<void> expectAdopted(String legacyId, {String id = 'run-1'}) async {
    final record = await activities.get(id);
    expect(record?.connectionProfileId, _current);
    expect(record?.idempotencyKey, 'key-$id');
    expect(
      await healthImports.localActivityIdFor(
        profileId: _current,
        sourceId: 'hk-$id',
      ),
      id,
    );
    expect(await healthSettings.isConnected(_current), isTrue);
    expect(await healthSettings.isAutoSyncEnabled(_current), isTrue);
    expect(await healthSettings.isConnected(legacyId), isFalse);
  }

  Future<void> expectUntouched(String legacyId, {String id = 'run-1'}) async {
    expect((await activities.get(id))?.connectionProfileId, legacyId);
    expect(
      await healthImports.isImported(profileId: _current, sourceId: 'hk-$id'),
      isFalse,
    );
    expect(await healthSettings.isConnected(_current), isFalse);
  }

  group('captureLegacyHint', () {
    test('records the stored legacy session and a username hash', () async {
      session = _session('42', username: 'Alex');
      await service.captureLegacyHint();

      final saved = await aliases.load();
      expect(saved.hints.keys, [_legacy]);
      expect(saved.hints[_legacy], isNotNull);
      expect(saved.hints[_legacy], isNot(contains('alex')));
    });

    test('ignores a session that already has a UUID id', () async {
      session = _session(_uuid, username: 'alex');
      await service.captureLegacyHint();
      expect((await aliases.load()).hints, isEmpty);
    });

    test('never throws when the session cannot be read', () async {
      service = LegacyProfileAdoptionService(
        readSession: () async => throw const FormatException('broken'),
        aliases: aliases,
        localActivities: activities,
        healthImports: healthImports,
        healthSettings: healthSettings,
      );
      await service.captureLegacyHint();
      expect((await aliases.load()).hints, isEmpty);
    });
  });

  group('resolveAfterSignIn', () {
    test('adopts silently when the same username signs in again', () async {
      session = _session('42', username: 'alex');
      await service.captureLegacyHint();
      await seedLegacyData(_legacy);

      session = _session(_uuid, username: 'ALEX ');
      await service.resolveAfterSignIn(confirm: answer(false));

      expect(asked, isEmpty);
      await expectAdopted(_legacy);
      expect((await aliases.load()).adopted, {_legacy: _current});
    });

    test('leaves data of a different known username alone', () async {
      session = _session('42', username: 'alex');
      await service.captureLegacyHint();
      await seedLegacyData(_legacy);

      session = _session(_uuid, username: 'sam');
      await service.resolveAfterSignIn(confirm: answer(true));

      expect(asked, isEmpty);
      await expectUntouched(_legacy);
    });

    test('asks when no username is known, and adopts on yes', () async {
      await seedLegacyData(_legacy);

      session = _session(_uuid);
      await service.resolveAfterSignIn(confirm: answer(true));

      expect(asked.single.legacyProfileId, _legacy);
      expect(asked.single.username, isNull);
      await expectAdopted(_legacy);
    });

    test('a "not mine" is remembered for that account', () async {
      await seedLegacyData(_legacy);
      session = _session(_uuid, username: 'sam');

      await service.resolveAfterSignIn(confirm: answer(false));
      await service.resolveAfterSignIn(confirm: answer(true));

      expect(asked, hasLength(1));
      await expectUntouched(_legacy);
    });

    test('an unanswered prompt is asked again at the next sign-in', () async {
      await seedLegacyData(_legacy);
      session = _session(_uuid);

      await service.resolveAfterSignIn(confirm: answer(null));
      await expectUntouched(_legacy);
      await service.resolveAfterSignIn(confirm: answer(true));

      expect(asked, hasLength(2));
      await expectAdopted(_legacy);
    });

    test('adopts at most one legacy profile per account', () async {
      await seedLegacyData(_legacyOther, id: 'run-7');
      await seedLegacyData(_legacy, id: 'run-42');
      session = _session(_uuid);

      // Sorted: '#42' before '#7'. Decline the first, accept the second.
      var calls = 0;
      await service.resolveAfterSignIn(
        confirm: (candidate) async {
          asked.add(candidate);
          return calls++ > 0;
        },
      );
      await service.resolveAfterSignIn(confirm: answer(true));

      expect(asked.map((c) => c.legacyProfileId), [_legacy, _legacyOther]);
      expect((await activities.get('run-7'))?.connectionProfileId, _current);
      expect((await activities.get('run-42'))?.connectionProfileId, _legacy);
    });

    test('ignores legacy data of another server', () async {
      await activities.upsert(
        _record('run-1', '$_otherOrigin#42', origin: _otherOrigin),
      );
      session = _session(_uuid);

      await service.resolveAfterSignIn(confirm: answer(true));

      expect(asked, isEmpty);
    });

    test('does nothing after a sign-in to a pre-v0.21 server', () async {
      await seedLegacyData(_legacyOther, id: 'run-7');
      session = _session('42', username: 'alex');

      await service.resolveAfterSignIn(confirm: answer(true));

      expect(asked, isEmpty);
      expect(
        (await activities.get('run-7'))?.connectionProfileId,
        _legacyOther,
      );
    });
  });

  group('reapply', () {
    test('moves records that reach an adopted legacy id later', () async {
      session = _session('42', username: 'alex');
      await service.captureLegacyHint();
      await seedLegacyData(_legacy);
      session = _session(_uuid, username: 'alex');
      await service.resolveAfterSignIn(confirm: answer(false));

      // A recording that was in progress across the app update finishes now.
      await activities.upsert(_record('late-run', _legacy));
      await service.reapply(session!.profile);

      expect((await activities.get('late-run'))?.connectionProfileId, _current);
    });

    test('moves nothing for a profile that adopted nothing', () async {
      await activities.upsert(_record('run-1', _legacy));
      await service.reapply(_session(_uuid).profile);
      expect((await activities.get('run-1'))?.connectionProfileId, _legacy);
    });
  });
}

AuthSession _session(String accountId, {String? username}) {
  return AuthSession(
    accountId: accountId,
    revision: 'rev',
    origin: _origin,
    connectionKind: ConnectionKind.selfHosted,
    accessToken: 'access',
    refreshToken: 'refresh',
    sessionId: 'session',
    accessTokenExpiresAt: DateTime.utc(2030),
    username: username,
  );
}

LocalActivityRecord _record(
  String id,
  String profileId, {
  String origin = _origin,
}) {
  final ended = DateTime.utc(2026, 11, 10, 7);
  return LocalActivityRecord(
    id: id,
    activityType: ActivityType.run,
    startedAt: ended.subtract(const Duration(minutes: 30)),
    endedAt: ended,
    elapsedDurationSeconds: 1800,
    distanceMeters: 5000,
    pointCount: 100,
    gpxFileName: '$id.gpx',
    uploadStatus: LocalActivityUploadStatus.pending,
    createdAt: ended,
    updatedAt: ended,
    idempotencyKey: 'key-$id',
    connectionOrigin: origin,
    connectionProfileId: profileId,
  );
}
