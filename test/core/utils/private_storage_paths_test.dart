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

    String legacyPathFor() =>
        '$legacyDirectory${Platform.pathSeparator}$databaseFileName';

    String targetPathFor() =>
        '${supportDirectory.path}${Platform.pathSeparator}'
        '$privateStorageDirectoryName${Platform.pathSeparator}'
        '$privateDatabaseDirectoryName${Platform.pathSeparator}$databaseFileName';

    Future<String> resolve() => privateDatabasePath(
      databaseFactory: databaseFactoryFfi,
      fileName: databaseFileName,
      supportDirectoryProvider: () async => supportDirectory,
    );

    test('resumes a move interrupted after the main database file', () async {
      final legacyPath = legacyPathFor();
      final targetPath = targetPathFor();
      await File(targetPath).create(recursive: true);
      await File(targetPath).writeAsString('database');
      await File('$legacyPath-wal').writeAsString('-wal');
      await File('$legacyPath-journal').writeAsString('-journal');

      expect(await resolve(), targetPath);

      expect(File(targetPath).readAsString(), completion('database'));
      expect(File('$targetPath-wal').readAsString(), completion('-wal'));
      expect(
        File('$targetPath-journal').readAsString(),
        completion('-journal'),
      );
      expect(File('$legacyPath-wal').existsSync(), isFalse);
      expect(File('$legacyPath-journal').existsSync(), isFalse);
    });

    test('finishes a copy-based move that left both copies', () async {
      // A cross-device move crashed after renaming the staged copy into place
      // but before deleting the source.
      final legacyPath = legacyPathFor();
      final targetPath = targetPathFor();
      await File(targetPath).create(recursive: true);
      await File(targetPath).writeAsString('database');
      await File(legacyPath).writeAsString('database');
      await File('$legacyPath-wal').writeAsString('-wal');

      expect(await resolve(), targetPath);

      expect(File(legacyPath).existsSync(), isFalse);
      expect(File('$legacyPath-wal').existsSync(), isFalse);
      expect(File('$targetPath-wal').readAsString(), completion('-wal'));
    });

    test('refuses to mix two different database copies', () async {
      final legacyPath = legacyPathFor();
      final targetPath = targetPathFor();
      await File(targetPath).create(recursive: true);
      await File(targetPath).writeAsString('new database');
      await File(legacyPath).writeAsString('old database');

      await expectLater(resolve(), throwsA(isA<FileSystemException>()));

      expect(File(legacyPath).readAsString(), completion('old database'));
      expect(File(targetPath).readAsString(), completion('new database'));
    });

    test('refuses legacy sidecars that the target already has', () async {
      final legacyPath = legacyPathFor();
      final targetPath = targetPathFor();
      await File(targetPath).create(recursive: true);
      await File(targetPath).writeAsString('database');
      await File('$targetPath-wal').writeAsString('new wal');
      await File('$legacyPath-wal').writeAsString('old wal');

      await expectLater(resolve(), throwsA(isA<FileSystemException>()));
      expect(File('$legacyPath-wal').existsSync(), isTrue);
    });
  });
}
