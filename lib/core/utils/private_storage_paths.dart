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
  const suffixes = ['', '-wal', '-shm', '-journal'];
  final legacyFiles = [
    for (final suffix in suffixes) File('$legacyPath$suffix'),
  ];
  final targetFiles = [
    for (final suffix in suffixes) File('$targetPath$suffix'),
  ];
  final hasLegacyFiles = legacyFiles.any((file) => file.existsSync());
  final hasTargetFiles = targetFiles.any((file) => file.existsSync());

  // Never combine source and target files from separate database copies.
  // Preflight the full SQLite set before changing anything so a later launch
  // can reliably retry an interrupted migration.
  if (hasLegacyFiles && hasTargetFiles) {
    throw FileSystemException(
      'Conflicting SQLite migration database',
      legacyDatabase.path,
    );
  }
  if (!hasLegacyFiles || hasTargetFiles) return;

  for (final suffix in suffixes) {
    final source = File('$legacyPath$suffix');
    if (!source.existsSync()) continue;
    await _moveFile(source, '$targetPath$suffix');
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

  final stagingPath = '$targetPath.migrating';
  final stagingFile = File(stagingPath);
  if (stagingFile.existsSync()) {
    await stagingFile.delete();
  }
  await source.copy(stagingPath);
  await stagingFile.rename(targetPath);
  await source.delete();
}
