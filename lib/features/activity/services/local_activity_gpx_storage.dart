// The async existence checks are deliberate: this runs on the UI isolate and
// the synchronous variants would block it on slow storage.
// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/services/activity_storage_paths.dart';
import 'package:path_provider/path_provider.dart';

class LocalActivityGpxStorage {
  LocalActivityGpxStorage({
    Future<Directory> Function()? supportDirectoryProvider,
  }) : _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  static const String gpxDirectoryName = 'gpx';
  static const String fileExtension = '.gpx';

  static const String _stagingExtension = '.tmp';

  final Future<Directory> Function() _supportDirectoryProvider;

  /// The one-time sweep of staging files a killed write left behind, shared
  /// so a concurrent first write cannot delete another write's staging file.
  Future<void>? _staleSweep;

  /// Writes [gpx] for [id] and returns the stored file name.
  ///
  /// The content is flushed to `<name>.tmp` and renamed over the final name,
  /// so a crash mid-write never leaves a truncated GPX under the real name.
  Future<String> write({required String id, required String gpx}) async {
    try {
      final directory = await _gpxDirectory(create: true);
      await (_staleSweep ??= _deleteStaleStagingFiles(directory));
      final fileName = _fileNameForId(id);
      final path = '${directory.path}${Platform.pathSeparator}$fileName';
      final staging = File('$path$_stagingExtension');
      await staging.writeAsString(gpx, flush: true);
      await staging.rename(path);
      return fileName;
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw AppException(AppErrorCode.activityLocalSaveFailed, cause: error);
    }
  }

  Future<String> readFilePath(String fileName) async {
    final safeFileName = _safeFileName(fileName);
    final directory = await _gpxDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}$safeFileName',
    );
    if (!await file.exists()) {
      throw const AppException(AppErrorCode.activityLocalGpxMissing);
    }
    return file.path;
  }

  Future<String> read(String fileName) async {
    final safeFileName = _safeFileName(fileName);
    final directory = await _gpxDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}$safeFileName',
    );
    if (!await file.exists()) {
      throw const AppException(AppErrorCode.activityLocalGpxMissing);
    }
    return file.readAsString();
  }

  Future<bool> exists(String fileName) async {
    final safeFileName = _safeFileName(fileName);
    final directory = await _gpxDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}$safeFileName',
    );
    return file.exists();
  }

  Future<void> delete(String fileName) async {
    try {
      final safeFileName = _safeFileName(fileName);
      final directory = await _gpxDirectory();
      final file = File(
        '${directory.path}${Platform.pathSeparator}$safeFileName',
      );
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw AppException(AppErrorCode.activityLocalDeleteFailed, cause: error);
    }
  }

  Future<Directory> _gpxDirectory({bool create = false}) async {
    final supportDirectory = await _supportDirectoryProvider();
    final root = activityStorageRoot(supportDirectory);
    final gpxDirectory = Directory(
      '${root.path}${Platform.pathSeparator}$gpxDirectoryName',
    );
    if (create && !await gpxDirectory.exists()) {
      await gpxDirectory.create(recursive: true);
    }
    return gpxDirectory;
  }

  Future<void> _deleteStaleStagingFiles(Directory directory) async {
    try {
      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith(_stagingExtension)) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Best effort: a leftover staging file is harmless and is overwritten
      // by the next write of the same id.
    }
  }

  String _fileNameForId(String id) {
    final safeId = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    if (safeId.isEmpty) {
      throw const AppException(AppErrorCode.activityLocalRecordInvalid);
    }
    return '$safeId$fileExtension';
  }

  String _safeFileName(String fileName) {
    if (RegExp(r'^[A-Za-z0-9_-]+\.gpx$').hasMatch(fileName)) {
      return fileName;
    }
    throw const AppException(AppErrorCode.activityLocalGpxMissing);
  }
}
