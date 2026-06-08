import 'dart:convert';
import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/repositories/active_activity_store.dart';
import 'package:endurain/features/activity/services/activity_storage_paths.dart';
import 'package:path_provider/path_provider.dart';

/// File-backed [ActiveActivityStore] using app-private support storage.
///
/// Layout:
/// ```text
/// <app-support>/activity_records/active/
///   session.json   // active session metadata only
///   points.jsonl   // one RecordedActivityPoint per line (append-only)
/// ```
///
/// Points are appended line-by-line so writes stay small and crash-friendly.
/// Diagnostics never include raw coordinates or file paths; only counts and
/// failure reasons are recorded.
class FileActiveActivityStore implements ActiveActivityStore {
  FileActiveActivityStore({
    Future<Directory> Function()? supportDirectoryProvider,
    DiagnosticsRecorder? diagnostics,
  }) : _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory,
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder();

  static const String activeDirectoryName = 'active';
  static const String sessionFileName = 'session.json';
  static const String pointsFileName = 'points.jsonl';

  final Future<Directory> Function() _supportDirectoryProvider;
  final DiagnosticsRecorder _diagnostics;

  @override
  Future<void> saveSession(ActiveActivitySession session) async {
    try {
      final file = await _sessionFile(create: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(session.toJson()),
        flush: true,
      );
    } catch (error) {
      throw _wrapWrite(error);
    }
  }

  @override
  Future<ActiveActivitySession?> loadSession() async {
    final file = await _sessionFile();
    if (!file.existsSync()) {
      return null;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        throw const FormatException('Active session root is not an object');
      }
      return ActiveActivitySession.fromJson(decoded);
    } on AppException {
      rethrow;
    } catch (error) {
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.activityActiveSessionRecovered,
        details: {'reason': error.runtimeType.toString()},
      );
      return null;
    }
  }

  @override
  Future<void> appendPoints(List<RecordedActivityPoint> points) async {
    if (points.isEmpty) {
      return;
    }
    try {
      final file = await _pointsFile(create: true);
      final buffer = StringBuffer();
      for (final point in points) {
        buffer.writeln(point.toJsonLine());
      }
      await file.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (error) {
      throw _wrapWrite(error);
    }
  }

  @override
  Future<List<RecordedActivityPoint>> readPoints({int sinceOffset = 0}) async {
    final file = await _pointsFile();
    if (!file.existsSync()) {
      return const <RecordedActivityPoint>[];
    }
    try {
      final lines = const LineSplitter().convert(await file.readAsString());
      final points = <RecordedActivityPoint>[];
      var index = 0;
      for (final line in lines) {
        if (line.trim().isEmpty) {
          continue;
        }
        final point = RecordedActivityPoint.tryParseLine(line);
        if (point == null) {
          _diagnostics.recordBreadcrumbSync(
            DiagnosticsEvents.activityActiveSessionRecovered,
            details: {'reason': 'malformedPoint'},
          );
          continue;
        }
        if (index >= sinceOffset) {
          points.add(point);
        }
        index++;
      }
      return points;
    } catch (error) {
      throw _wrapRead(error);
    }
  }

  @override
  Future<int> pointCount() async {
    final file = await _pointsFile();
    if (!file.existsSync()) {
      return 0;
    }
    try {
      final lines = const LineSplitter().convert(await file.readAsString());
      var count = 0;
      for (final line in lines) {
        if (RecordedActivityPoint.tryParseLine(line) != null) {
          count++;
        }
      }
      return count;
    } catch (error) {
      throw _wrapRead(error);
    }
  }

  @override
  Future<void> replacePoints(List<RecordedActivityPoint> points) async {
    try {
      final file = await _pointsFile(create: true);
      final buffer = StringBuffer();
      for (final point in points) {
        buffer.writeln(point.toJsonLine());
      }
      await file.writeAsString(buffer.toString(), flush: true);
    } catch (error) {
      throw _wrapWrite(error);
    }
  }

  @override
  Future<void> complete(ActiveActivitySession session) {
    return saveSession(session);
  }

  @override
  Future<void> clear() async {
    try {
      final directory = await _activeDirectory();
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    } catch (error) {
      throw _wrapWrite(error);
    }
  }

  Future<Directory> _activeDirectory({bool create = false}) async {
    final supportDirectory = await _supportDirectoryProvider();
    final root = activityStorageRoot(supportDirectory);
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}$activeDirectoryName',
    );
    if (create && !directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return directory;
  }

  Future<File> _sessionFile({bool create = false}) async {
    final directory = await _activeDirectory(create: create);
    return File('${directory.path}${Platform.pathSeparator}$sessionFileName');
  }

  Future<File> _pointsFile({bool create = false}) async {
    final directory = await _activeDirectory(create: create);
    return File('${directory.path}${Platform.pathSeparator}$pointsFileName');
  }

  AppException _wrapWrite(Object error) {
    if (error is AppException) {
      return error;
    }
    return AppException(
      AppErrorCode.activeActivityStoreWriteFailed,
      cause: error,
    );
  }

  AppException _wrapRead(Object error) {
    if (error is AppException) {
      return error;
    }
    return AppException(
      AppErrorCode.activeActivityStoreReadFailed,
      cause: error,
    );
  }
}
