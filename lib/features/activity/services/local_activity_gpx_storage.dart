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

  final Future<Directory> Function() _supportDirectoryProvider;

  Future<String> write({required String id, required String gpx}) async {
    try {
      final directory = await _gpxDirectory(create: true);
      final fileName = _fileNameForId(id);
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      await file.writeAsString(gpx, flush: true);
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
    if (!file.existsSync()) {
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
    if (!file.existsSync()) {
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
    return file.existsSync();
  }

  Future<void> delete(String fileName) async {
    try {
      final safeFileName = _safeFileName(fileName);
      final directory = await _gpxDirectory();
      final file = File(
        '${directory.path}${Platform.pathSeparator}$safeFileName',
      );
      if (file.existsSync()) {
        file.deleteSync();
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
    if (create && !gpxDirectory.existsSync()) {
      gpxDirectory.createSync(recursive: true);
    }
    return gpxDirectory;
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
