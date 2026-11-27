import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture guard: features that sit below the others must not reach back
/// into them.
///
/// - `auth` signs the user in and knows nothing about the map; the one thing
///   it needs from it (saving the server's tile URL after sign-in) is injected
///   by the composition root.
/// - `settings` hosts screens for other features' preferences, but those
///   screens live with their feature (for example the audio-announcement
///   screen is in `activity`). The only things left are the health-access
///   entries the device-access screen shows, listed below. Adding to the list
///   should be a deliberate decision, not a side effect of a convenient
///   import.
void main() {
  final featureImport = RegExp(
    r"import 'package:endurain/features/([a-z_]+)/([a-z_/]+\.dart)'",
  );

  /// Imports of `features/<feature>/<path>` found in `lib/features/<owner>`.
  List<String> importsFrom(String owner) {
    final dir = Directory('lib/features/$owner');
    expect(dir.existsSync(), isTrue, reason: 'Run from the package root.');
    final found = <String>[];
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      for (final match in featureImport.allMatches(entity.readAsStringSync())) {
        found.add('${match.group(1)}/${match.group(2)}');
      }
    }
    return found;
  }

  test('auth does not import the map feature', () {
    final offenders = importsFrom('auth')
        .where((target) => target.startsWith('map/'))
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'Inject what auth needs from the map through the composition root '
          '(lib/app/navigation/app_screens.dart). Offending imports: '
          '${offenders.join(', ')}',
    );
  });

  test('settings imports no activity code and only allowed health entries', () {
    const allowedHealthImports = <String>{
      'health/controllers/health_sync_controller.dart',
      'health/models/health_authorization_status.dart',
      'health/models/health_sdk_status.dart',
      'health/screens/health_access_screen.dart',
    };

    final offenders = importsFrom('settings')
        .where(
          (target) =>
              target.startsWith('activity/') ||
              (target.startsWith('health/') &&
                  !allowedHealthImports.contains(target)),
        )
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'Put screens for another feature\'s settings inside that feature '
          'and wire them in SettingsDestinations. Offending imports: '
          '${offenders.join(', ')}',
    );
  });
}
