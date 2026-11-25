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
  // The main file moves first, so its absence from the legacy directory while
  // the target holds it marks a migration interrupted between files.
  const suffixes = ['', '-wal', '-shm', '-journal'];
  final pending = <String>[];
  for (final suffix in suffixes) {
    final source = File('$legacyPath$suffix');
    if (!source.existsSync()) continue;
    final target = File('$targetPath$suffix');
    if (target.existsSync() && await _sameContents(source, target)) {
      // A cross-device move copies, renames, then deletes the source; a crash
      // before that delete leaves two identical copies. Finish the move.
      await source.delete();
      continue;
    }
    pending.add(suffix);
  }
  if (pending.isEmpty) return;

  final resuming =
      !File(legacyPath).existsSync() && File(targetPath).existsSync();
  final conflicting = pending.any(
    (suffix) => File('$targetPath$suffix').existsSync(),
  );
  final hasTargetFiles = suffixes.any(
    (suffix) => File('$targetPath$suffix').existsSync(),
  );

  // Never combine source and target files from separate database copies: the
  // only mix allowed is the remaining sidecars of the database already moved.
  // Preflight the full SQLite set before changing anything so a later launch
  // can reliably retry an interrupted migration.
  if (conflicting || (hasTargetFiles && !resuming)) {
    throw FileSystemException(
      'Conflicting SQLite migration database',
      legacyPath,
    );
  }

  for (final suffix in pending) {
    await _moveFile(File('$legacyPath$suffix'), '$targetPath$suffix');
  }
}

Future<bool> _sameContents(File a, File b) async {
  if (await a.length() != await b.length()) return false;
  final aBytes = await a.readAsBytes();
  final bBytes = await b.readAsBytes();
  for (var i = 0; i < aBytes.length; i++) {
    if (aBytes[i] != bBytes[i]) return false;
  }
  return true;
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
