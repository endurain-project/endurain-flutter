import 'dart:io';

import 'package:endurain/core/services/app_services.dart';
import 'package:endurain/core/services/platform/share_service.dart';
import 'package:endurain/features/activity/controllers/local_activity_history_controller_factory.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_share_service.dart';
import '../../../helpers/sqlite_local_activity_repository.dart';

void main() {
  group('createLocalActivityHistoryController', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'endurain_history_factory_',
      );
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('builds from scoped app services', () async {
      final repository = _repositoryFor(tempDirectory);
      final record = await _createRecord(repository, id: 'scoped_record');
      final services = _FakeAppServices(
        repository: repository,
        uploadService: _uploadServiceReturning(201),
        retentionSettingsRepository: const _FakeRetentionSettings(
          retainUploadedGpx: true,
        ),
      );
      final controller = createLocalActivityHistoryController(
        services: services,
        removeImportProvenance: (_) async {},
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.records.single.id, record.id);
    });

    test('prefers explicit screen overrides over app services', () async {
      final repository = _repositoryFor(tempDirectory);
      final record = await _createRecord(repository, id: 'override_record');
      final services = _ThrowingAppServices();
      final controller = createLocalActivityHistoryController(
        services: services,
        repository: repository,
        uploadService: _uploadServiceReturning(201),
        retentionSettingsRepository: const _FakeRetentionSettings(
          retainUploadedGpx: true,
        ),
        removeImportProvenance: (_) async {},
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.records.single.id, record.id);
    });
  });
}

class _FakeAppServices extends AppServices {
  _FakeAppServices({
    required this._repository,
    required ActivityUploadService uploadService,
    required this._retentionSettingsRepository,
  }) : _uploadService = uploadService;

  final LocalActivityRepository _repository;
  final ActivityUploadService _uploadService;
  final ActivityRetentionSettingsRepository _retentionSettingsRepository;

  @override
  LocalActivityRepository get localActivities => _repository;

  @override
  ActivityUploadService get activityUpload => _uploadService;

  @override
  ActivityRetentionSettingsRepository get activityRetentionSettings =>
      _retentionSettingsRepository;

  @override
  ShareService get share => FakeShareService();
}

class _ThrowingAppServices extends AppServices {
  @override
  LocalActivityRepository get localActivities {
    throw StateError('default repository should not be used');
  }

  @override
  ActivityUploadService get activityUpload {
    throw StateError('default upload service should not be used');
  }

  @override
  ActivityRetentionSettingsRepository get activityRetentionSettings {
    throw StateError('default retention repository should not be used');
  }
}

class _FakeRetentionSettings implements ActivityRetentionSettingsRepository {
  const _FakeRetentionSettings({required this.retainUploadedGpx});

  final bool retainUploadedGpx;

  @override
  Future<bool> isRetainUploadedGpxEnabled() async => retainUploadedGpx;

  @override
  Future<void> setRetainUploadedGpxEnabled(bool enabled) async {}
}

LocalActivityRepository _repositoryFor(Directory directory) {
  return createTestLocalActivityRepository(directory);
}

Future<LocalActivityRecord> _createRecord(
  LocalActivityRepository repository, {
  required String id,
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
    uploadStatus: LocalActivityUploadStatus.pending,
    createdAt: DateTime.utc(2026, 6, 2, 10, 31),
    updatedAt: DateTime.utc(2026, 6, 2, 10, 31),
  );
  await repository.upsert(record);
  return record;
}

ActivityUploadService _uploadServiceReturning(int statusCode) {
  return ActivityUploadService(
    config: const ActivityUploadConfig(endpoint: '/upload', fieldName: 'file'),
    uploadFile: (_, _, _, {idempotencyKey}) async {
      return http.StreamedResponse(const Stream<List<int>>.empty(), statusCode);
    },
  );
}
