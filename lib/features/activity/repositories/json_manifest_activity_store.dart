import 'dart:convert';
import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_store.dart';
import 'package:endurain/features/activity/services/activity_storage_paths.dart';
import 'package:path_provider/path_provider.dart';

/// File-backed [LocalActivityStore] that persists metadata in a JSON manifest
/// (`index.json`) under the app support directory.
class JsonManifestActivityStore implements LocalActivityStore {
  JsonManifestActivityStore({
    Future<Directory> Function()? supportDirectoryProvider,
    DiagnosticsRecorder? diagnostics,
  }) : _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory,
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder();

  static const String _manifestFileName = 'index.json';

  final Future<Directory> Function() _supportDirectoryProvider;
  final DiagnosticsRecorder _diagnostics;

  @override
  Future<List<LocalActivityRecord>> list() async {
    final records = await _readRecords();
    records.sort(_endedAtDescending);
    return records;
  }

  @override
  Future<LocalActivityRecord?> get(String id) async {
    final records = await _readRecords();
    for (final record in records) {
      if (record.id == id) {
        return record;
      }
    }
    return null;
  }

  @override
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

  @override
  Future<void> delete(String id) async {
    final records = await _readRecords();
    records.removeWhere((item) => item.id == id);
    await _writeRecords(records, AppErrorCode.activityLocalDeleteFailed);
  }

  @override
  Future<List<LocalActivityRecord>> listPage({
    required int offset,
    required int limit,
  }) async {
    final all = await list();
    if (offset >= all.length) {
      return const <LocalActivityRecord>[];
    }
    final end = (offset + limit).clamp(0, all.length);
    return all.sublist(offset, end);
  }

  @override
  Future<int> count() async => (await list()).length;

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
