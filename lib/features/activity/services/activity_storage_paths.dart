library;

import 'dart:io';

/// Path constants and helpers shared by all activity-related stores.
///
/// The layout is:
/// ```
/// <app-support>/
///   activity_records/           ← [rootDirectoryName]
///     active/                   ← FileActiveActivityStore
///       session.json
///       points.jsonl
///     gpx/                      ← LocalActivityGpxStorage
///       <id>.gpx
/// ```
///
/// The names here must stay in sync with the Android `ActiveActivityStore` and
/// the iOS `ActiveActivityStore` so either recorder can recover state written
/// by the other.
const String activityStorageRootDir = 'activity_records';

/// Returns the root `activity_records` directory under [baseDirectory],
/// creating it when [create] is `true`.
Directory activityStorageRoot(Directory baseDirectory, {bool create = false}) {
  final dir = Directory(
    '${baseDirectory.path}${Platform.pathSeparator}$activityStorageRootDir',
  );
  if (create && !dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}
