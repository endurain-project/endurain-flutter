import 'dart:io';

import 'package:endurain/core/utils/private_storage_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  group('privateDatabasePath', () {
    late Directory supportDirectory;
    late String legacyDirectory;
    late String databaseFileName;

    setUp(() async {
      supportDirectory = await Directory.systemTemp.createTemp(
        'endurain_support_',
      );
      legacyDirectory = await databaseFactoryFfi.getDatabasesPath();
      await Directory(legacyDirectory).create(recursive: true);
      databaseFileName =
          'private_storage_paths_${DateTime.now().microsecondsSinceEpoch}.db';
    });

    tearDown(() async {
      if (supportDirectory.existsSync()) {
        await supportDirectory.delete(recursive: true);
      }
      for (final suffix in ['', '-wal', '-shm', '-journal']) {
        final legacyFile = File(
          '$legacyDirectory${Platform.pathSeparator}$databaseFileName$suffix',
        );
        if (legacyFile.existsSync()) {
          await legacyFile.delete();
        }
      }
    });

    test('creates private storage and migrates database sidecars', () async {
      final legacyPath =
          '$legacyDirectory${Platform.pathSeparator}$databaseFileName';
      await File(legacyPath).writeAsString('database');
      for (final suffix in const ['-wal', '-shm', '-journal']) {
        await File('$legacyPath$suffix').writeAsString(suffix);
      }

      final targetPath = await privateDatabasePath(
        databaseFactory: databaseFactoryFfi,
        fileName: databaseFileName,
        supportDirectoryProvider: () async => supportDirectory,
      );

      expect(
        targetPath,
        '${supportDirectory.path}${Platform.pathSeparator}'
        '$privateStorageDirectoryName${Platform.pathSeparator}'
        '$privateDatabaseDirectoryName${Platform.pathSeparator}$databaseFileName',
      );
      expect(File(targetPath).readAsString(), completion('database'));
      for (final suffix in const ['-wal', '-shm', '-journal']) {
        expect(File('$targetPath$suffix').readAsString(), completion(suffix));
        expect(File('$legacyPath$suffix').existsSync(), isFalse);
      }
      expect(File(legacyPath).existsSync(), isFalse);
    });
  });
}
