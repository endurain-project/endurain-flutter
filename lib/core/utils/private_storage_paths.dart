import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

const String privateStorageDirectoryName = 'endurain_private';
const String privateDatabaseDirectoryName = 'databases';
const int _crossDeviceLinkErrorCode = 18;

Future<String> privateDatabasePath({
  required DatabaseFactory databaseFactory,
  required String fileName,
  Future<Directory> Function()? supportDirectoryProvider,
}) async {
  final supportDirectory =
      await (supportDirectoryProvider ?? getApplicationSupportDirectory)();
  final databaseDirectory = Directory(
    '${supportDirectory.path}${Platform.pathSeparator}'
    '$privateStorageDirectoryName${Platform.pathSeparator}'
    '$privateDatabaseDirectoryName',
  );
  if (!databaseDirectory.existsSync()) {
    databaseDirectory.createSync(recursive: true);
  }
  final targetPath =
      '${databaseDirectory.path}${Platform.pathSeparator}$fileName';
  await _migrateLegacyDatabase(
    databaseFactory: databaseFactory,
    fileName: fileName,
    targetPath: targetPath,
  );
  return targetPath;
}

Future<void> _migrateLegacyDatabase({
  required DatabaseFactory databaseFactory,
  required String fileName,
  required String targetPath,
}) async {
  final legacyDirectory = await databaseFactory.getDatabasesPath();
  final legacyPath = '$legacyDirectory${Platform.pathSeparator}$fileName';
  final legacyDatabase = File(legacyPath);
  final targetDatabase = File(targetPath);

  for (final suffix in const ['-wal', '-shm', '-journal']) {
    final source = File('$legacyPath$suffix');
    if (!source.existsSync()) continue;
    final target = File('$targetPath$suffix');
    if (target.existsSync()) {
      throw FileSystemException(
        'Conflicting SQLite migration sidecar',
        source.path,
      );
    }
    await _moveFile(source, target.path);
  }

  if (targetDatabase.existsSync()) {
    if (legacyDatabase.existsSync()) {
      throw FileSystemException(
        'Conflicting SQLite migration database',
        legacyDatabase.path,
      );
    }
    return;
  }
  if (legacyDatabase.existsSync()) {
    await _moveFile(legacyDatabase, targetPath);
  }
}

Future<void> _moveFile(File source, String targetPath) async {
  try {
    await source.rename(targetPath);
    return;
  } on FileSystemException catch (error) {
    if (error.osError?.errorCode != _crossDeviceLinkErrorCode) {
      rethrow;
    }
  }

  await source.copy(targetPath);
  await source.delete();
}
