import 'dart:convert';
import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/services/activity_storage_paths.dart';
import 'package:endurain/features/activity/services/local_activity_gpx_storage.dart';
import 'package:path_provider/path_provider.dart';

class LocalActivityRepository {
  LocalActivityRepository({
    Future<Directory> Function()? supportDirectoryProvider,
    LocalActivityGpxStorage? gpxStorage,
    DiagnosticsRecorder? diagnostics,
  }) : _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory,
       _gpxStorage =
           gpxStorage ??
           LocalActivityGpxStorage(
             supportDirectoryProvider: supportDirectoryProvider,
           ),
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder();

  static const String _manifestFileName = 'index.json';

  final Future<Directory> Function() _supportDirectoryProvider;
  final LocalActivityGpxStorage _gpxStorage;
  final DiagnosticsRecorder _diagnostics;

  Future<List<LocalActivityRecord>> list() async {
    final records = await _readRecords();
    records.sort(_endedAtDescending);
    return records;
  }

  Future<LocalActivityRecord?> get(String id) async {
    final records = await _readRecords();
    for (final record in records) {
      if (record.id == id) {
        return record;
      }
    }
    return null;
  }

  Future<String> writeGpx({required String id, required String gpx}) {
    return _gpxStorage.write(id: id, gpx: gpx);
  }

  Future<String> readGpxFilePath(LocalActivityRecord record) {
    return _gpxStorage.readFilePath(record.gpxFileName);
  }

  Future<bool> hasGpx(LocalActivityRecord record) {
    return _gpxStorage.exists(record.gpxFileName);
  }

  Future<void> deleteGpx(LocalActivityRecord record) {
    return _gpxStorage.delete(record.gpxFileName);
  }

  Future<void> upsert(LocalActivityRecord record) async {
    final records = await _readRecords();
    final index = records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      records.add(record);
    } else {
      records[index] = record;
    }
    records.sort(_endedAtDescending);
    await _writeRecords(records, AppErrorCode.activityLocalSaveFailed);
  }

  Future<void> delete(String id) async {
    final records = await _readRecords();
    LocalActivityRecord? record;
    for (final item in records) {
      if (item.id == id) {
        record = item;
        break;
      }
    }
    if (record == null) {
      return;
    }

    await _gpxStorage.delete(record.gpxFileName);
    records.removeWhere((item) => item.id == id);
    await _writeRecords(records, AppErrorCode.activityLocalDeleteFailed);
  }

  Future<List<LocalActivityRecord>> _readRecords() async {
    final file = await _manifestFile();
    if (!file.existsSync()) {
      return <LocalActivityRecord>[];
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Manifest root is not an object');
      }
      final records = decoded['records'];
      if (records is! List) {
        throw const FormatException('Manifest records are not a list');
      }
      return records
          .whereType<Map<dynamic, dynamic>>()
          .map(LocalActivityRecord.fromJson)
          .toList(growable: true);
    } catch (error) {
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.activityLocalManifestRecovered,
        details: {'reason': error.runtimeType.toString()},
      );
      return <LocalActivityRecord>[];
    }
  }

  Future<void> _writeRecords(
    List<LocalActivityRecord> records,
    AppErrorCode errorCode,
  ) async {
    try {
      final file = await _manifestFile(create: true);
      final payload = {
        'schemaVersion': 1,
        'records': [for (final record in records) record.toJson()],
      };
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
        flush: true,
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw AppException(errorCode, cause: error);
    }
  }

  Future<File> _manifestFile({bool create = false}) async {
    final supportDirectory = await _supportDirectoryProvider();
    final rootDirectory = activityStorageRoot(supportDirectory, create: create);
    return File(
      '${rootDirectory.path}${Platform.pathSeparator}$_manifestFileName',
    );
  }

  int _endedAtDescending(LocalActivityRecord left, LocalActivityRecord right) {
    return right.endedAt.compareTo(left.endedAt);
  }
}
