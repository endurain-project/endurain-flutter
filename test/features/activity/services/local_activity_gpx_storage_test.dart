import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/services/local_activity_gpx_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalActivityGpxStorage', () {
    late Directory tempDirectory;
    late LocalActivityGpxStorage storage;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'endurain_gpx_storage_',
      );
      storage = LocalActivityGpxStorage(
        supportDirectoryProvider: () async => tempDirectory,
      );
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('writes GPX files with stable private file names', () async {
      final fileName = await storage.write(id: 'activity_1', gpx: '<gpx />');
      final filePath = await storage.readFilePath(fileName);

      expect(fileName, 'activity_1.gpx');
      expect(File(filePath).readAsStringSync(), '<gpx />');
      expect(filePath, contains('activity_records'));
      expect(filePath, contains('gpx'));
    });

    test('sanitizes local ids before using them as file names', () async {
      final fileName = await storage.write(id: '../activity 1', gpx: '<gpx />');

      expect(fileName, '___activity_1.gpx');
      expect(await storage.exists(fileName), isTrue);
    });

    test('deletes GPX files by retained file name', () async {
      final fileName = await storage.write(id: 'activity_1', gpx: '<gpx />');

      await storage.delete(fileName);

      expect(await storage.exists(fileName), isFalse);
    });

    test(
      'leaves no staging file after a write and replaces in place',
      () async {
        await storage.write(id: 'activity_1', gpx: '<gpx>old</gpx>');
        final fileName = await storage.write(
          id: 'activity_1',
          gpx: '<gpx>new</gpx>',
        );

        final dir = File(await storage.readFilePath(fileName)).parent;
        expect(
          dir.listSync().map((e) => e.path.split(Platform.pathSeparator).last),
          ['activity_1.gpx'],
        );
        expect(await storage.read(fileName), '<gpx>new</gpx>');
      },
    );

    test('sweeps staging files left by an interrupted write', () async {
      final fileName = await storage.write(id: 'activity_1', gpx: '<gpx />');
      final dir = File(await storage.readFilePath(fileName)).parent;
      File('${dir.path}/activity_2.gpx.tmp').writeAsStringSync('<gpx trunc');
      // A fresh instance models the app restarting after the crash.
      final restarted = LocalActivityGpxStorage(
        supportDirectoryProvider: () async => tempDirectory,
      );

      await restarted.write(id: 'activity_3', gpx: '<gpx />');

      expect(File('${dir.path}/activity_2.gpx.tmp').existsSync(), isFalse);
      expect(await restarted.exists('activity_1.gpx'), isTrue);
      expect(await restarted.exists('activity_3.gpx'), isTrue);
    });

    test('reads back written GPX contents', () async {
      final fileName = await storage.write(
        id: 'activity_1',
        gpx: '<gpx>route</gpx>',
      );

      expect(await storage.read(fileName), '<gpx>route</gpx>');
    });

    test('reading a missing file throws activityLocalGpxMissing', () async {
      expect(
        () => storage.read('missing.gpx'),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.activityLocalGpxMissing,
          ),
        ),
      );
    });

    test('rejects unsafe file names without exposing paths', () async {
      expect(
        () => storage.readFilePath('../private.gpx'),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.activityLocalGpxMissing,
          ),
        ),
      );
    });
  });
}
