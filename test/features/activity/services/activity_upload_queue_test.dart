import 'dart:async';
import 'dart:io';

import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_upload_queue.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/sqlite_local_activity_repository.dart';

void main() {
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
          uploadFile: (_, _, _, {idempotencyKey}) async {
            calls++;
            return http.StreamedResponse(const Stream<List<int>>.empty(), 500);
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
          uploadFile: (_, _, _, {idempotencyKey}) async {
            calls++;
            return http.StreamedResponse(const Stream<List<int>>.empty(), 201);
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
          uploadFile: (_, _, _, {idempotencyKey}) async {
            calls++;
            await Future<void>.delayed(Duration.zero);
            return http.StreamedResponse(const Stream<List<int>>.empty(), 201);
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
          uploadFile: (_, _, _, {idempotencyKey}) async {
            attemptedKeys.add(idempotencyKey);
            if (!uploadStarted.isCompleted) {
              uploadStarted.complete();
              await releaseUpload.future;
            }
            return http.StreamedResponse(const Stream<List<int>>.empty(), 201);
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
  });
}

ActivityUploadService _uploadServiceCapturing(
  List<String?> keys, {
  required int status,
}) {
  return ActivityUploadService(
    config: const ActivityUploadConfig(endpoint: '/upload', fieldName: 'file'),
    uploadFile: (_, _, _, {idempotencyKey}) async {
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
  );
  await repository.upsert(record);
  return record;
}
