import 'dart:async';
import 'dart:io';

import 'package:endurain/core/diagnostics/diagnostics_events.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_upload_queue.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/local_activity_listing.dart';
import '../../../helpers/recording_diagnostics.dart';
import '../../../helpers/sqlite_local_activity_repository.dart';

void main() {
  retryTimerTests();
  group('ActivityUploadQueue', () {
    late Directory tempDirectory;
    late LocalActivityRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'endurain_upload_queue_',
      );
      repository = createTestLocalActivityRepository(tempDirectory);
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('drains pending and failed records and uploads them', () async {
      await _createRecord(
        repository,
        id: 'q_pending',
        status: LocalActivityUploadStatus.pending,
      );
      await _createRecord(
        repository,
        id: 'q_failed',
        status: LocalActivityUploadStatus.failed,
      );
      await _createRecord(
        repository,
        id: 'q_uploaded',
        status: LocalActivityUploadStatus.uploaded,
      );

      final attemptedKeys = <String?>[];
      final queue = ActivityUploadQueue(
        repository: repository,
        uploadService: _uploadServiceCapturing(attemptedKeys, status: 201),
      );

      await queue.drain();

      // Only the pending + failed records are attempted (not the uploaded one),
      // each carrying its id as the idempotency key.
      expect(attemptedKeys.toSet(), {'q_pending', 'q_failed'});
      final records = await repository.list();
      final byId = {for (final r in records) r.id: r};
      expect(
        byId['q_pending']!.uploadStatus,
        LocalActivityUploadStatus.uploaded,
      );
      expect(
        byId['q_failed']!.uploadStatus,
        LocalActivityUploadStatus.uploaded,
      );
      expect(
        byId['q_uploaded']!.uploadStatus,
        LocalActivityUploadStatus.uploaded,
      );
    });

    test('keeps failed records failed and keeps draining the rest', () async {
      await _createRecord(
        repository,
        id: 'q_a',
        status: LocalActivityUploadStatus.failed,
      );
      await _createRecord(
        repository,
        id: 'q_b',
        status: LocalActivityUploadStatus.failed,
      );

      var calls = 0;
      final queue = ActivityUploadQueue(
        repository: repository,
        uploadService: ActivityUploadService(
          config: const ActivityUploadConfig(
            endpoint: '/upload',
            fieldName: 'file',
          ),
          uploadFile:
              (
                _,
                _,
                _, {
                idempotencyKey,
                expectedOrigin,
                expectedProfileId,
              }) async {
                calls++;
                return http.StreamedResponse(
                  const Stream<List<int>>.empty(),
                  500,
                );
              },
        ),
      );

      await queue.drain();

      // Both records were attempted even though the first failed.
      expect(calls, 2);
      final records = await repository.list();
      for (final record in records) {
        expect(record.uploadStatus, LocalActivityUploadStatus.failed);
      }
    });

    test('stops at the first auth failure and keeps the backlog', () async {
      await _createRecord(
        repository,
        id: 'q_auth_a',
        status: LocalActivityUploadStatus.pending,
      );
      await _createRecord(
        repository,
        id: 'q_auth_b',
        status: LocalActivityUploadStatus.pending,
      );
      final attemptedKeys = <String?>[];
      final queue = ActivityUploadQueue(
        repository: repository,
        uploadService: _uploadServiceCapturing(attemptedKeys, status: 401),
      );

      await queue.drain();

      // The lost session would fail every record the same way: only the first
      // is attempted.
      expect(attemptedKeys, hasLength(1));
      final records = await repository.list();
      for (final record in records) {
        expect(record.autoRetryEligible, isTrue);
      }

      // After signing in again, the next drain uploads the whole backlog.
      final retriedKeys = <String?>[];
      await ActivityUploadQueue(
        repository: repository,
        uploadService: _uploadServiceCapturing(retriedKeys, status: 201),
      ).drain();
      expect(retriedKeys.toSet(), {'q_auth_a', 'q_auth_b'});
    });

    test('skips failed records that require manual retry', () async {
      await _createRecord(
        repository,
        id: 'q_terminal',
        status: LocalActivityUploadStatus.failed,
        autoRetryEligible: false,
      );
      final attemptedKeys = <String?>[];
      final queue = ActivityUploadQueue(
        repository: repository,
        uploadService: _uploadServiceCapturing(attemptedKeys, status: 201),
      );

      await queue.drain();

      expect(attemptedKeys, isEmpty);
      expect(
        (await repository.get('q_terminal'))?.uploadStatus,
        LocalActivityUploadStatus.failed,
      );
    });

    test('does nothing when the upload service is not configured', () async {
      await _createRecord(
        repository,
        id: 'q_unconfigured',
        status: LocalActivityUploadStatus.failed,
      );
      var calls = 0;
      final queue = ActivityUploadQueue(
        repository: repository,
        uploadService: ActivityUploadService(
          uploadFile:
              (
                _,
                _,
                _, {
                idempotencyKey,
                expectedOrigin,
                expectedProfileId,
              }) async {
                calls++;
                return http.StreamedResponse(
                  const Stream<List<int>>.empty(),
                  201,
                );
              },
        ),
      );

      await queue.drain();

      expect(calls, 0);
    });

    test('does not drain while upload is unauthorized (guest mode)', () async {
      await _createRecord(
        repository,
        id: 'q_guest',
        status: LocalActivityUploadStatus.pending,
      );
      final attemptedKeys = <String?>[];
      final queue = ActivityUploadQueue(
        repository: repository,
        uploadService: _uploadServiceCapturing(attemptedKeys, status: 201),
        isUploadAuthorized: () async => false,
      );

      await queue.drain();

      expect(attemptedKeys, isEmpty);
      final records = await repository.list();
      expect(records.single.uploadStatus, LocalActivityUploadStatus.pending);
    });

    test('drains once upload becomes authorized', () async {
      await _createRecord(
        repository,
        id: 'q_authorized',
        status: LocalActivityUploadStatus.pending,
      );
      var authorized = false;
      final attemptedKeys = <String?>[];
      final queue = ActivityUploadQueue(
        repository: repository,
        uploadService: _uploadServiceCapturing(attemptedKeys, status: 201),
        isUploadAuthorized: () async => authorized,
      );

      await queue.drain();
      expect(attemptedKeys, isEmpty);

      authorized = true;
      await queue.drain();
      expect(attemptedKeys, ['q_authorized']);
    });

    test('drains only records for the active connection origin', () async {
      final active = await _createRecord(
        repository,
        id: 'q_active',
        status: LocalActivityUploadStatus.pending,
        connectionOrigin: 'https://active.example',
        connectionProfileId: 'profile-active',
      );
      final other = await _createRecord(
        repository,
        id: 'q_other',
        status: LocalActivityUploadStatus.pending,
        connectionOrigin: 'https://other.example',
        connectionProfileId: 'profile-other',
      );
      final attemptedKeys = <String?>[];
      final queue = ActivityUploadQueue(
        repository: repository,
        uploadService: _uploadServiceCapturing(attemptedKeys, status: 201),
        activeConnectionProfile: () async => const ConnectionProfile(
          id: 'profile-active',
          origin: 'https://active.example',
          kind: ConnectionKind.selfHosted,
        ),
      );

      await queue.drain();

      expect(attemptedKeys, [active.id]);
      expect(
        (await repository.get(active.id))?.uploadStatus,
        LocalActivityUploadStatus.uploaded,
      );
      expect(
        (await repository.get(other.id))?.uploadStatus,
        LocalActivityUploadStatus.pending,
      );
    });

    test('binds guest records to the active connection and uploads', () async {
      final guest = await _createRecord(
        repository,
        id: 'q_guest',
        status: LocalActivityUploadStatus.pending,
        connectionOrigin: null,
        connectionProfileId: null,
      );
      final attemptedKeys = <String?>[];
      final queue = ActivityUploadQueue(
        repository: repository,
        uploadService: _uploadServiceCapturing(attemptedKeys, status: 201),
        activeConnectionProfile: () async => const ConnectionProfile(
          id: 'profile-active',
          origin: 'https://active.example',
          kind: ConnectionKind.selfHosted,
        ),
      );

      await queue.drain();

      // The formerly-unassigned guest record is bound to the active connection
      // and then uploaded.
      expect(attemptedKeys, [guest.id]);
      final bound = await repository.get(guest.id);
      expect(bound?.uploadStatus, LocalActivityUploadStatus.uploaded);
      expect(bound?.connectionOrigin, 'https://active.example');
      expect(bound?.connectionProfileId, 'profile-active');
    });

    test('reconciles the active profile before selecting records', () async {
      final record = await _createRecord(
        repository,
        id: 'q_legacy',
        status: LocalActivityUploadStatus.pending,
        connectionOrigin: 'https://active.example',
        connectionProfileId: 'https://active.example#42',
      );
      const profile = ConnectionProfile(
        id: 'https://active.example#uuid',
        origin: 'https://active.example',
        kind: ConnectionKind.selfHosted,
      );
      final reconciled = <String>[];
      final attemptedKeys = <String?>[];
      final queue = ActivityUploadQueue(
        repository: repository,
        uploadService: _uploadServiceCapturing(attemptedKeys, status: 201),
        activeConnectionProfile: () async => profile,
        reconcileProfile: (active) async {
          reconciled.add(active.id);
          await repository.rebindConnectionProfile(
            origin: active.origin,
            fromProfileId: 'https://active.example#42',
            toProfileId: active.id,
            updatedAt: DateTime.utc(2026, 11, 17),
          );
        },
      );

      await queue.drain();

      expect(reconciled, [profile.id]);
      expect(attemptedKeys, [record.id]);
      expect(
        (await repository.get(record.id))?.uploadStatus,
        LocalActivityUploadStatus.uploaded,
      );
    });

    test('concurrent drain calls share a single run', () async {
      await _createRecord(
        repository,
        id: 'q_single',
        status: LocalActivityUploadStatus.failed,
      );
      var calls = 0;
      final queue = ActivityUploadQueue(
        repository: repository,
        uploadService: ActivityUploadService(
          config: const ActivityUploadConfig(
            endpoint: '/upload',
            fieldName: 'file',
          ),
          uploadFile:
              (
                _,
                _,
                _, {
                idempotencyKey,
                expectedOrigin,
                expectedProfileId,
              }) async {
                calls++;
                await Future<void>.delayed(Duration.zero);
                return http.StreamedResponse(
                  const Stream<List<int>>.empty(),
                  201,
                );
              },
        ),
      );

      await Future.wait([queue.drain(), queue.drain(), queue.drain()]);

      // Only one drain ran, so the single record was attempted once.
      expect(calls, 1);
    });

    test('a drain requested in flight performs a follow-up scan', () async {
      await _createRecord(
        repository,
        id: 'q_first',
        status: LocalActivityUploadStatus.pending,
      );
      final uploadStarted = Completer<void>();
      final releaseUpload = Completer<void>();
      final attemptedKeys = <String?>[];
      final queue = ActivityUploadQueue(
        repository: repository,
        uploadService: ActivityUploadService(
          config: const ActivityUploadConfig(
            endpoint: '/upload',
            fieldName: 'file',
          ),
          uploadFile:
              (
                _,
                _,
                _, {
                idempotencyKey,
                expectedOrigin,
                expectedProfileId,
              }) async {
                attemptedKeys.add(idempotencyKey);
                if (!uploadStarted.isCompleted) {
                  uploadStarted.complete();
                  await releaseUpload.future;
                }
                return http.StreamedResponse(
                  const Stream<List<int>>.empty(),
                  201,
                );
              },
        ),
      );

      final firstDrain = queue.drain();
      await uploadStarted.future;
      await _createRecord(
        repository,
        id: 'q_second',
        status: LocalActivityUploadStatus.pending,
      );
      final joinedDrain = queue.drain();
      releaseUpload.complete();
      await Future.wait([firstDrain, joinedDrain]);

      expect(attemptedKeys, ['q_first', 'q_second']);
    });

    test('connectivity signal triggers a drain when online', () async {
      await _createRecord(
        repository,
        id: 'q_conn',
        status: LocalActivityUploadStatus.failed,
      );
      final controller = StreamController<bool>();
      final attemptedKeys = <String?>[];
      final queue = ActivityUploadQueue(
        repository: repository,
        uploadService: _uploadServiceCapturing(attemptedKeys, status: 201),
        connectivitySignal: controller.stream,
      );
      addTearDown(queue.dispose);
      addTearDown(controller.close);

      controller.add(false); // offline: no drain
      await pumpEventQueue();
      expect(attemptedKeys, isEmpty);

      controller.add(true); // online: drain
      for (var i = 0; i < 100 && attemptedKeys.isEmpty; i++) {
        await pumpEventQueue();
      }

      expect(attemptedKeys, ['q_conn']);
    });

    group('persisted retry backoff', () {
      final failedAt = DateTime.utc(2026, 6, 3, 8);

      test('a transient failure counts and schedules the next try', () async {
        await _createRecord(
          repository,
          id: 'q_backoff',
          status: LocalActivityUploadStatus.pending,
        );
        final queue = ActivityUploadQueue(
          repository: repository,
          uploadService: _failingUploadService(
            500,
            backoff: ActivityUploadBackoff(random: () => 0),
          ),
          now: () => failedAt,
        );

        await queue.drain();

        final record = (await repository.get('q_backoff'))!;
        expect(record.uploadStatus, LocalActivityUploadStatus.failed);
        expect(record.uploadAttemptCount, 1);
        expect(
          record.nextUploadAttemptAt,
          failedAt.add(const Duration(minutes: 1)),
        );
      });

      test('skips a record until its backoff elapses', () async {
        await _createRecord(
          repository,
          id: 'q_wait',
          status: LocalActivityUploadStatus.failed,
          nextUploadAttemptAt: DateTime.utc(2026, 6, 3, 9),
          uploadAttemptCount: 2,
        );
        final attemptedKeys = <String?>[];
        var now = DateTime.utc(2026, 6, 3, 8, 59);
        final queue = ActivityUploadQueue(
          repository: repository,
          uploadService: _uploadServiceCapturing(attemptedKeys, status: 201),
          now: () => now,
        );

        await queue.drain();
        expect(attemptedKeys, isEmpty);

        now = DateTime.utc(2026, 6, 3, 9);
        await queue.drain();
        expect(attemptedKeys, ['q_wait']);
        final record = (await repository.get('q_wait'))!;
        expect(record.uploadStatus, LocalActivityUploadStatus.uploaded);
        expect(record.uploadAttemptCount, 0);
        expect(record.nextUploadAttemptAt, isNull);
      });

      test('keeps doubling the wait over consecutive failures', () async {
        await _createRecord(
          repository,
          id: 'q_double',
          status: LocalActivityUploadStatus.pending,
        );
        var now = failedAt;
        final queue = ActivityUploadQueue(
          repository: repository,
          uploadService: _failingUploadService(
            503,
            backoff: ActivityUploadBackoff(random: () => 0),
          ),
          now: () => now,
        );

        await queue.drain();
        now = (await repository.get('q_double'))!.nextUploadAttemptAt!;
        await queue.drain();

        final record = (await repository.get('q_double'))!;
        expect(record.uploadAttemptCount, 2);
        expect(record.nextUploadAttemptAt, now.add(const Duration(minutes: 2)));
      });

      test('an auth failure does not back off', () async {
        await _createRecord(
          repository,
          id: 'q_auth_backoff',
          status: LocalActivityUploadStatus.pending,
        );
        final queue = ActivityUploadQueue(
          repository: repository,
          uploadService: _failingUploadService(401),
          now: () => failedAt,
        );

        await queue.drain();

        final record = (await repository.get('q_auth_backoff'))!;
        expect(record.uploadAttemptCount, 0);
        expect(record.nextUploadAttemptAt, isNull);
        expect(record.autoRetryEligible, isTrue);
      });

      test('a manual retry ignores the backoff', () async {
        final record = await _createRecord(
          repository,
          id: 'q_manual',
          status: LocalActivityUploadStatus.failed,
          nextUploadAttemptAt: DateTime.utc(2099),
          uploadAttemptCount: 5,
        );
        final service = _uploadServiceCapturing([], status: 201);

        final result = await service.performUploadAttempt(
          record: record,
          repository: repository,
        );

        expect(result.uploadStatus, LocalActivityUploadStatus.uploaded);
        expect(result.uploadAttemptCount, 0);
        expect(result.nextUploadAttemptAt, isNull);
      });

      test('still finishes a deferred GPX cleanup during a backoff', () async {
        final record = await _createRecord(
          repository,
          id: 'q_cleanup',
          status: LocalActivityUploadStatus.uploaded,
          nextUploadAttemptAt: DateTime.utc(2099),
        );
        await repository.upsert(record.copyWith(gpxCleanupPending: true));
        final attemptedKeys = <String?>[];
        final queue = ActivityUploadQueue(
          repository: repository,
          uploadService: _uploadServiceCapturing(attemptedKeys, status: 201),
          retentionSettingsRepository: null,
          now: () => failedAt,
        );

        await queue.drain();

        // Cleanup involves no upload.
        expect(attemptedKeys, isEmpty);
        expect((await repository.get('q_cleanup'))!.gpxCleanupPending, isFalse);
      });
    });

    test(
      'a failure outside per-record handling is recorded, not thrown',
      () async {
        final diagnostics = RecordingDiagnostics();
        final queue = ActivityUploadQueue(
          repository: repository,
          uploadService: _uploadServiceCapturing([], status: 201),
          activeConnectionProfile: () async => throw StateError('profile gone'),
          diagnostics: diagnostics,
        );

        await queue.drain();

        expect(
          diagnostics.single(DiagnosticsEvents.activityUploadQueueDrainFailed),
          isNotNull,
        );
      },
    );
  });
}

ActivityUploadService _failingUploadService(
  int status, {
  ActivityUploadBackoff backoff = const ActivityUploadBackoff(),
}) {
  return ActivityUploadService(
    config: const ActivityUploadConfig(endpoint: '/upload', fieldName: 'file'),
    backoff: backoff,
    uploadFile:
        (_, _, _, {idempotencyKey, expectedOrigin, expectedProfileId}) async {
          return http.StreamedResponse(const Stream<List<int>>.empty(), status);
        },
  );
}

ActivityUploadService _uploadServiceCapturing(
  List<String?> keys, {
  required int status,
}) {
  return ActivityUploadService(
    config: const ActivityUploadConfig(endpoint: '/upload', fieldName: 'file'),
    uploadFile:
        (_, _, _, {idempotencyKey, expectedOrigin, expectedProfileId}) async {
          keys.add(idempotencyKey);
          return http.StreamedResponse(const Stream<List<int>>.empty(), status);
        },
  );
}

Future<LocalActivityRecord> _createRecord(
  LocalActivityRepository repository, {
  required String id,
  required LocalActivityUploadStatus status,
  String? connectionOrigin = 'https://example.test',
  String? connectionProfileId = 'profile-1',
  bool autoRetryEligible = true,
  int uploadAttemptCount = 0,
  DateTime? nextUploadAttemptAt,
}) async {
  final fileName = await repository.writeGpx(id: id, gpx: '<gpx />');
  final record = LocalActivityRecord(
    id: id,
    activityType: ActivityType.run,
    startedAt: DateTime.utc(2026, 6, 2, 10),
    endedAt: DateTime.utc(2026, 6, 2, 10, 30),
    elapsedDurationSeconds: 1800,
    distanceMeters: 5000,
    pointCount: 40,
    gpxFileName: fileName,
    uploadStatus: status,
    createdAt: DateTime.utc(2026, 6, 2, 10, 31),
    updatedAt: DateTime.utc(2026, 6, 2, 10, 31),
    connectionOrigin: connectionOrigin,
    connectionProfileId: connectionProfileId,
    autoRetryEligible: autoRetryEligible,
    uploadAttemptCount: uploadAttemptCount,
    nextUploadAttemptAt: nextUploadAttemptAt,
  );
  await repository.upsert(record);
  return record;
}

/// Serves canned upload-queue candidates and counts how often they are read,
/// so the retry timer can be observed without a database.
class _ScriptedCandidatesRepository extends LocalActivityRepository {
  _ScriptedCandidatesRepository(this.responses)
    : super(supportDirectoryProvider: () async => Directory.systemTemp);

  final List<List<LocalActivityRecord>> responses;
  int reads = 0;

  @override
  Future<List<LocalActivityRecord>> listUploadQueueCandidates() async {
    final index = reads < responses.length ? reads : responses.length - 1;
    reads++;
    return responses[index];
  }
}

LocalActivityRecord _backingOffRecord(String id, DateTime next) {
  return LocalActivityRecord(
    id: id,
    activityType: ActivityType.run,
    startedAt: DateTime.utc(2026, 6, 2, 10),
    endedAt: DateTime.utc(2026, 6, 2, 10, 30),
    elapsedDurationSeconds: 1800,
    distanceMeters: 5000,
    pointCount: 40,
    gpxFileName: '$id.gpx',
    uploadStatus: LocalActivityUploadStatus.failed,
    createdAt: DateTime.utc(2026, 6, 2, 10, 31),
    updatedAt: DateTime.utc(2026, 6, 2, 10, 31),
    nextUploadAttemptAt: next,
  );
}

void retryTimerTests() {
  final start = DateTime.utc(2026, 6, 2, 12);

  group('ActivityUploadQueue retry timer', () {
    test('re-drains when the earliest backoff elapses', () {
      fakeAsync((async) {
        final repository = _ScriptedCandidatesRepository([
          [
            _backingOffRecord('later', start.add(const Duration(minutes: 9))),
            _backingOffRecord('soon', start.add(const Duration(minutes: 5))),
          ],
          const [],
        ]);
        final queue = ActivityUploadQueue(
          repository: repository,
          uploadService: _failingUploadService(500),
          now: () => async.getClock(start).now(),
        );

        unawaited(queue.drain());
        async.flushMicrotasks();
        expect(repository.reads, 1);

        async.elapse(const Duration(minutes: 4, seconds: 59));
        expect(repository.reads, 1);

        async.elapse(const Duration(seconds: 1));
        expect(repository.reads, 2);
        queue.dispose();
      });
    });

    test('dispose cancels a pending retry', () {
      fakeAsync((async) {
        final repository = _ScriptedCandidatesRepository([
          [_backingOffRecord('soon', start.add(const Duration(minutes: 5)))],
        ]);
        final queue = ActivityUploadQueue(
          repository: repository,
          uploadService: _failingUploadService(500),
          now: () => async.getClock(start).now(),
        );
        unawaited(queue.drain());
        async.flushMicrotasks();

        queue.dispose();
        async.elapse(const Duration(hours: 1));

        expect(repository.reads, 1);
      });
    });

    test('a later drain replaces the previous timer', () {
      fakeAsync((async) {
        final repository = _ScriptedCandidatesRepository([
          [_backingOffRecord('a', start.add(const Duration(minutes: 5)))],
          [_backingOffRecord('a', start.add(const Duration(minutes: 30)))],
          const [],
        ]);
        final queue = ActivityUploadQueue(
          repository: repository,
          uploadService: _failingUploadService(500),
          now: () => async.getClock(start).now(),
        );
        unawaited(queue.drain());
        async.flushMicrotasks();
        unawaited(queue.drain());
        async.flushMicrotasks();
        expect(repository.reads, 2);

        async.elapse(const Duration(minutes: 6));
        expect(repository.reads, 2);

        async.elapse(const Duration(minutes: 24));
        expect(repository.reads, 3);
        queue.dispose();
      });
    });

    test('does not arm a timer when nothing is backing off', () {
      fakeAsync((async) {
        final repository = _ScriptedCandidatesRepository([const []]);
        final queue = ActivityUploadQueue(
          repository: repository,
          uploadService: _failingUploadService(500),
          now: () => async.getClock(start).now(),
        );
        unawaited(queue.drain());
        async.flushMicrotasks();

        expect(async.nonPeriodicTimerCount, 0);
        queue.dispose();
      });
    });
  });
}
