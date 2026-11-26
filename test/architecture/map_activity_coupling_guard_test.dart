import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture guard: the map feature reaches into the activity feature
/// only through a few narrow entry points.
///
/// The map used to import eleven activity files (dialogs, countdown services,
/// formatters, ...) to host the recording flow. That flow now lives behind
/// `ActivityRecordingOverlay`, so the map needs only the controller it drives
/// and the overlay widget. Adding to this list should be a deliberate
/// decision, not a side effect of a convenient import.
void main() {
  const allowedActivityImports = <String>{
    'controllers/activity_recording_controller.dart',
    'widgets/activity_recording_overlay.dart',
  };

  final activityImport = RegExp(
    r"import 'package:endurain/features/activity/([a-z_/]+\.dart)'",
  );

  test('map imports only the allowed activity entry points', () {
    final mapDir = Directory('lib/features/map');
    expect(mapDir.existsSync(), isTrue, reason: 'Run from the package root.');

    final offenders = <String>[];
    for (final entity in mapDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      for (final match in activityImport.allMatches(
        entity.readAsStringSync(),
      )) {
        final target = match.group(1)!;
        if (!allowedActivityImports.contains(target)) {
          offenders.add('${entity.path} -> activity/$target');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Compose recording UI inside the activity feature (e.g. in '
          'ActivityRecordingOverlay) instead of importing it into the map. '
          'Offending imports: ${offenders.join(', ')}',
    );
  });
}
