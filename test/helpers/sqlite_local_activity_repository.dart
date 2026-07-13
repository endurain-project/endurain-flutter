import 'dart:io';

import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/repositories/sqflite_activity_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Builds an isolated SQLite metadata store for tests, backed by a database
/// file under [directory].
///
/// Uses [databaseFactoryFfiNoIsolate] so database operations resolve on the
/// test's own event loop. The default [databaseFactoryFfi] runs SQLite in a
/// background isolate, whose cross-isolate completions are not deterministically
/// flushed by `pumpEventQueue`, making timing-sensitive tests flaky.
SqfliteActivityStore createTestActivityStore(Directory directory) {
  sqfliteFfiInit();
  return SqfliteActivityStore(
    databaseFactory: databaseFactoryFfiNoIsolate,
    databasePath: '${directory.path}${Platform.pathSeparator}activity.db',
  );
}

/// Builds a SQLite-backed [LocalActivityRepository] for tests.
///
/// GPX files live under [supportDirectory]; activity metadata uses an
/// in-process ffi SQLite database stored in the same directory so each test
/// gets an isolated database that is removed with its temp directory.
LocalActivityRepository createTestLocalActivityRepository(
  Directory supportDirectory,
) {
  return LocalActivityRepository(
    supportDirectoryProvider: () async => supportDirectory,
    store: createTestActivityStore(supportDirectory),
  );
}
