import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture guard: source files stay small enough to review.
///
/// New files must stay within [_maxLines]. Files that were already larger when
/// this guard was added are capped at their size then, so they can shrink but
/// never grow; lower or drop an entry when a file is split.
const int _maxLines = 500;

const Map<String, int> _legacyCaps = {
  'lib/features/activity/services/activity_recording_service.dart': 812,
  'lib/features/activity/services/activity_upload_service.dart': 556,
  'lib/features/auth/screens/login_screen.dart': 572,
  'lib/features/health/services/health_package_platform_adapter.dart': 685,
  'lib/features/health/services/health_sync_service.dart': 620,
  'lib/features/sensors/screens/sensor_settings_screen.dart': 512,
  'android/app/src/main/kotlin/com/endurain/endurain/activity/ActivityRecorderService.kt':
      921,
  'android/wear/src/main/kotlin/com/endurain/endurain/wear/WorkoutRecorder.kt':
      586,
  'ios/EndurainWatch/WorkoutManager.swift': 556,
};

/// Source roots checked, with the file extension each one holds. Generated
/// localizations (lib/l10n) are excluded.
const Map<String, String> _roots = {
  'lib': '.dart',
  'android/app/src/main/kotlin': '.kt',
  'android/wear/src/main/kotlin': '.kt',
  'android/watch_shared/kotlin': '.kt',
  'ios/Runner': '.swift',
  'ios/EndurainWatch': '.swift',
  'ios/Shared': '.swift',
};

void main() {
  Iterable<File> sources() sync* {
    for (final MapEntry(key: root, value: extension) in _roots.entries) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is File &&
            entity.path.endsWith(extension) &&
            !entity.path.startsWith('lib/l10n/')) {
          yield entity;
        }
      }
    }
  }

  int lineCount(File file) => file.readAsLinesSync().length;

  test('source files stay within their line budget', () {
    final offenders = <String>[];
    for (final file in sources()) {
      final path = file.path;
      final limit = _legacyCaps[path] ?? _maxLines;
      final lines = lineCount(file);
      if (lines > limit) {
        offenders.add('$path: $lines lines (limit $limit)');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Split these files into smaller, focused units. A legacy file may '
          'only shrink; new files are limited to $_maxLines lines.\n'
          '${offenders.join('\n')}',
    );
  });

  test('legacy caps point at existing files that still need them', () {
    final stale = <String>[];
    for (final MapEntry(key: path, value: cap) in _legacyCaps.entries) {
      final file = File(path);
      if (!file.existsSync()) {
        stale.add('$path no longer exists');
      } else if (lineCount(file) <= _maxLines) {
        stale.add('$path is within $_maxLines lines; remove its cap ($cap)');
      }
    }

    expect(stale, isEmpty, reason: stale.join('\n'));
  });
}
