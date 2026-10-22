import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture guard: dependencies point inward.
///
/// `core/` and `shared/` are foundations that features build on, so they must
/// not import `features/` or `app/`. `app/` is the composition root (DI,
/// router, shell widgets) and is the only layer allowed to know every feature.
void main() {
  final import = RegExp(r"import 'package:endurain/(features|app)/");

  List<File> dartFilesUnder(String dir) => [
    for (final entity in Directory(dir).listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart')) entity,
  ];

  for (final layer in ['lib/core', 'lib/shared']) {
    test('$layer does not import features/ or app/', () {
      final offenders = [
        for (final file in dartFilesUnder(layer))
          if (import.hasMatch(file.readAsStringSync())) file.path,
      ];

      expect(
        offenders,
        isEmpty,
        reason:
            '$layer must stay free of feature and composition-root code. '
            'Move the wiring into lib/app or the code into its feature. '
            'Offending files: ${offenders.join(', ')}',
      );
    });
  }
}
