import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture guard: `AppServices` is constructed only by the composition
/// root, and the former `AppServices.instance` global is never reintroduced.
///
/// The composition root (`main`) constructs its own `AppServices` and injects
/// it into the root `App`, which exposes it through `AppScope`. Feature code,
/// services, controllers, and widgets MUST obtain services via
/// `AppScope.servicesOf(context)` so future managed, multi-environment, or
/// account-scoped builds can isolate service instances.
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

  test('the AppServices.instance global is never reintroduced', () {
    final offenders = <String>[
      for (final file in libDartFiles())
        if (file.value.contains('AppServices.instance')) file.key,
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'AppServices must not expose a global instance. Inject it from the '
          'composition root and obtain services via AppScope.servicesOf. '
          'Offending files: ${offenders.join(', ')}',
    );
  });

  test('AppServices is constructed only by the composition root', () {
    // Files permitted to construct an AppServices, relative to lib/.
    const allowedFiles = <String>{
      // Composition root entry point.
      'main.dart',
      // Declares the class (constructor) and builds the test-only fallback.
      'app.dart',
      'core/services/app_services.dart',
    };

    final offenders = <String>[
      for (final file in libDartFiles())
        if (!allowedFiles.contains(file.key) &&
            file.value.contains('AppServices('))
          file.key,
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'AppServices() must only be constructed by the composition root '
          '(main.dart / app.dart). Feature code must use '
          'AppScope.servicesOf(context). Offending files: '
          '${offenders.join(', ')}',
    );
  });
}
