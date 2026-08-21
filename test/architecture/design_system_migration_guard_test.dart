import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture guard: the app is fully migrated to the standalone
/// `material_ui`/`cupertino_ui` packages (Flutter 3.47+) and never
/// reintroduces the legacy, now-decoupled core-SDK imports.
///
/// The generated `lib/l10n/app_localizations*.dart` files are the sole
/// permitted exception: `flutter gen-l10n` still emits
/// `package:flutter_localizations/flutter_localizations.dart` and the legacy
/// `GlobalMaterialLocalizations`/`GlobalCupertinoLocalizations` trio, which
/// produce types material_ui/cupertino_ui widgets don't recognize. App code
/// must combine `AppLocalizations.delegate` with material_ui's
/// `GlobalMaterialLocalizations.delegates` via
/// `appLocalizationsDelegates` (see `lib/core/localization/app_locales.dart`)
/// instead of the generated `AppLocalizations.localizationsDelegates`.
void main() {
  final libDir = Directory('lib');

  List<MapEntry<String, String>> libDartFiles() {
    return [
      for (final entity in libDir.listSync(recursive: true))
        if (entity is File && entity.path.endsWith('.dart'))
          MapEntry(
            entity.path.substring('lib/'.length).replaceAll(r'\', '/'),
            entity.readAsStringSync(),
          ),
    ];
  }

  test('no file imports the legacy core-SDK material/cupertino libraries', () {
    final offenders = <String>[
      for (final file in libDartFiles())
        if (file.value.contains('package:flutter/material.dart') ||
            file.value.contains('package:flutter/cupertino.dart'))
          file.key,
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'Use package:material_ui/material_ui.dart and '
          'package:cupertino_ui/cupertino_ui.dart instead of the legacy '
          'core-SDK design libraries. Offending files: '
          '${offenders.join(', ')}',
    );
  });

  test('no app widget uses the generated (legacy) localizationsDelegates', () {
    // l10n/app_localizations.dart: the generated file itself.
    // core/localization/app_locales.dart: only mentions the generated
    // getter by name in a doc comment, explaining what to use instead.
    const allowedFiles = <String>{
      'l10n/app_localizations.dart',
      'core/localization/app_locales.dart',
    };

    final offenders = <String>[
      for (final file in libDartFiles())
        if (!allowedFiles.contains(file.key) &&
            file.value.contains('AppLocalizations.localizationsDelegates'))
          file.key,
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'App widgets must use appLocalizationsDelegates (from '
          'lib/core/localization/app_locales.dart), not the generated '
          'AppLocalizations.localizationsDelegates, which still wires the '
          'legacy flutter_localizations trio. Offending files: '
          '${offenders.join(', ')}',
    );
  });
}
