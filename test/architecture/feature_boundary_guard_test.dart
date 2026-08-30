import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture guard: a feature's persistence backend stays private to it.
///
/// A `…Store` is the concrete persistence implementation sitting behind a
/// feature's repository facade (`SqfliteActivityStore`, `FileActiveActivityStore`,
/// `SqfliteHealthImportStore`, …). The repository is the swappable public seam
/// every other feature depends on; the store is an implementation detail.
///
/// Two invariants keep that seam real:
/// 1. No feature imports another feature's store — otherwise a contributor can
///    quietly couple a feature to another feature's database schema, and the
///    repository stops being swappable.
/// 2. Stores appear only in repositories, services, and the composition root —
///    never in a screen, controller, widget, or model, which must go through
///    the repository.
void main() {
  final libDir = Directory('lib');

  List<MapEntry<String, String>> libDartFiles() {
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'Test must run from the package root so lib/ is resolvable.',
    );
    return [
      for (final entity in libDir.listSync(recursive: true))
        if (entity is File && entity.path.endsWith('.dart'))
          MapEntry(
            entity.path.substring('lib/'.length).replaceAll(r'\', '/'),
            entity.readAsStringSync(),
          ),
    ];
  }

  // Matches an import of a `…store.dart` under any feature's repositories/.
  final storeImport = RegExp(
    r"import 'package:endurain/features/([a-z_]+)/repositories/"
    r"([a-z_]*store)\.dart'",
  );

  /// The feature a lib-relative path belongs to, or `null` outside features/.
  String? featureOf(String path) {
    final segments = path.split('/');
    if (segments.length < 2 || segments.first != 'features') {
      return null;
    }
    return segments[1];
  }

  /// The layer folder a feature file lives in (`repositories`, `screens`, …).
  String? layerOf(String path) {
    final segments = path.split('/');
    return segments.length < 3 ? null : segments[2];
  }

  // Wiring every feature together is the composition root's whole job.
  bool isCompositionRoot(String path) =>
      path.startsWith('core/services/modules/') ||
      path == 'core/services/app_services.dart' ||
      path == 'core/services/app_infrastructure.dart';

  test('no feature imports another feature\'s store', () {
    final offenders = <String>[];
    for (final file in libDartFiles()) {
      if (isCompositionRoot(file.key)) {
        continue;
      }
      for (final match in storeImport.allMatches(file.value)) {
        final target = match.group(1)!;
        if (featureOf(file.key) == target) {
          continue;
        }
        offenders.add('${file.key} -> $target/${match.group(2)}.dart');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A store is private to its feature. Depend on that feature\'s '
          'repository instead, and let the composition root wire the store. '
          'Offending imports: ${offenders.join(', ')}',
    );
  });

  test('stores are reached only through repositories and services', () {
    const allowedLayers = <String>{'repositories', 'services'};

    final offenders = <String>[];
    for (final file in libDartFiles()) {
      if (isCompositionRoot(file.key) || featureOf(file.key) == null) {
        continue;
      }
      if (allowedLayers.contains(layerOf(file.key))) {
        continue;
      }
      if (storeImport.hasMatch(file.value)) {
        offenders.add(file.key);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Screens, controllers, widgets, and models must not touch a '
          'persistence store; go through the feature repository so the '
          'backend stays swappable. Offending files: ${offenders.join(', ')}',
    );
  });
}
