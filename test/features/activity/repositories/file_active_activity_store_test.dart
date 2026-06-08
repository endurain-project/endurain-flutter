import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/repositories/file_active_activity_store.dart';
import 'package:endurain/features/activity/services/activity_storage_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileActiveActivityStore', () {
    late Directory tempDirectory;
    late FileActiveActivityStore store;

    final startedAt = DateTime.utc(2026, 6, 3, 9);

    RecordedActivityPoint point({
      int segmentIndex = 0,
      double latitude = 41,
      double longitude = -8,
      int second = 0,
    }) {
      return RecordedActivityPoint(
        timestamp: startedAt.add(Duration(seconds: second)),
        latitude: latitude,
        longitude: longitude,
        segmentIndex: segmentIndex,
      );
    }

    ActiveActivitySession session() {
      return ActiveActivitySession(
        localSessionId: 'session_1',
        activityType: ActivityType.run,
        status: ActiveActivityStatus.recording,
        startedAt: startedAt,
      );
    }

    Directory activeDirectory() {
      return Directory(
        '${tempDirectory.path}${Platform.pathSeparator}'
        '$activityStorageRootDir'
        '${Platform.pathSeparator}'
        '${FileActiveActivityStore.activeDirectoryName}',
      );
    }

    File sessionFile() {
      return File(
        '${activeDirectory().path}${Platform.pathSeparator}'
        '${FileActiveActivityStore.sessionFileName}',
      );
    }

    File pointsFile() {
      return File(
        '${activeDirectory().path}${Platform.pathSeparator}'
        '${FileActiveActivityStore.pointsFileName}',
      );
    }

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'endurain_active_store_',
      );
      store = FileActiveActivityStore(
        supportDirectoryProvider: () async => tempDirectory,
      );
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('saves and loads session metadata', () async {
      await store.saveSession(session());

      final loaded = await store.loadSession();
      expect(loaded, isNotNull);
      expect(loaded!.localSessionId, 'session_1');
      expect(loaded.status, ActiveActivityStatus.recording);
    });

    test('returns null when no session file exists', () async {
      expect(await store.loadSession(), isNull);
    });

    test('recovers from malformed session JSON by returning null', () async {
      await store.saveSession(session());
      sessionFile().writeAsStringSync('{ not valid json');

      expect(await store.loadSession(), isNull);
    });

    test('clears session metadata and points', () async {
      await store.saveSession(session());
      await store.appendPoints([point()]);

      await store.clear();

      expect(sessionFile().existsSync(), isFalse);
      expect(pointsFile().existsSync(), isFalse);
      expect(await store.loadSession(), isNull);
    });

    test('appends and reads all points', () async {
      await store.appendPoints([point(second: 0), point(second: 1)]);
      await store.appendPoints([point(second: 2)]);

      final points = await store.readPoints();
      expect(points, hasLength(3));
      expect(await store.pointCount(), 3);
    });

    test('reads points since an offset', () async {
      await store.appendPoints([
        point(second: 0),
        point(second: 1),
        point(second: 2),
      ]);

      final points = await store.readPoints(sinceOffset: 2);
      expect(points, hasLength(1));
      expect(
        points.single.timestamp,
        startedAt.add(const Duration(seconds: 2)),
      );
    });

    test('reading an empty file returns no points', () async {
      expect(await store.readPoints(), isEmpty);
      expect(await store.pointCount(), 0);
    });

    test('skips a malformed point line during recovery', () async {
      await store.appendPoints([point(second: 0)]);
      pointsFile().writeAsStringSync('not json\n', mode: FileMode.append);
      await store.appendPoints([point(second: 2)]);

      final points = await store.readPoints();
      expect(points, hasLength(2));
      expect(await store.pointCount(), 2);
    });

    test('point offsets ignore malformed point lines', () async {
      await store.appendPoints([point(second: 0)]);
      pointsFile().writeAsStringSync('not json\n', mode: FileMode.append);
      await store.appendPoints([point(second: 2), point(second: 3)]);

      final points = await store.readPoints(sinceOffset: 2);

      expect(points, hasLength(1));
      expect(
        points.single.timestamp,
        startedAt.add(const Duration(seconds: 3)),
      );
    });

    test('replaces all stored points', () async {
      await store.appendPoints([point(second: 0), point(second: 1)]);

      await store.replacePoints([point(segmentIndex: 1, second: 5)]);

      final points = await store.readPoints();
      expect(points, hasLength(1));
      expect(points.single.segmentIndex, 1);
    });

    test('serializes concurrent file operations', () async {
      var activeProviderCalls = 0;
      var maxActiveProviderCalls = 0;
      final serializedStore = FileActiveActivityStore(
        supportDirectoryProvider: () async {
          activeProviderCalls += 1;
          if (activeProviderCalls > maxActiveProviderCalls) {
            maxActiveProviderCalls = activeProviderCalls;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
          activeProviderCalls -= 1;
          return tempDirectory;
        },
      );

      await Future.wait([
        serializedStore.saveSession(session()),
        serializedStore.appendPoints([point(second: 0)]),
        serializedStore.readPoints(),
        serializedStore.pointCount(),
        serializedStore.replacePoints([point(segmentIndex: 1, second: 5)]),
      ]);

      expect(maxActiveProviderCalls, 1);
    });

    test('complete persists final session metadata', () async {
      await store.complete(
        session().copyWith(
          status: ActiveActivityStatus.completed,
          endedAt: startedAt.add(const Duration(minutes: 30)),
        ),
      );

      final loaded = await store.loadSession();
      expect(loaded!.status, ActiveActivityStatus.completed);
      expect(loaded.endedAt, isNotNull);
    });

    test('wraps write failures as AppException', () async {
      final failingStore = FileActiveActivityStore(
        supportDirectoryProvider: () async =>
            throw const FileSystemException('no support dir'),
      );

      await expectLater(
        failingStore.saveSession(session()),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.activeActivityStoreWriteFailed,
          ),
        ),
      );
    });
  });
}
