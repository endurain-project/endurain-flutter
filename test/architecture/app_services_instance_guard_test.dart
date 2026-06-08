import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture guard: `AppServices.instance` is a last-resort fallback only.
///
/// The composition root (`main`) constructs its own `AppServices` and injects
/// it into the root `App`, which exposes it through `AppScope`. Feature code,
/// services, controllers, and widgets MUST obtain services via
/// `AppScope.servicesOf(context)` so future managed, multi-environment, or
/// account-scoped builds can isolate service instances.
///
/// This test fails if `AppServices.instance` is referenced anywhere in `lib/`
/// outside the small allowlist below, catching accidental reintroduction of
/// the global into feature code.
void main() {
  test('AppServices.instance is only used inside the composition root', () {
    // Files permitted to reference the global fallback, relative to lib/.
    const allowedFiles = <String>{
      // Composition root entry point.
      'main.dart',
      // Declares the fallback singleton.
      'core/services/app_services.dart',
      // The `AppScope.servicesOf` last-resort fallback for unscoped contexts.
      'core/services/app_scope.dart',
      // Root `App` test-only fallback when no services are injected.
      'app.dart',
    };

    final libDir = Directory('lib');
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'Test must run from the package root so lib/ is resolvable.',
    );

    final offenders = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final relativePath = entity.path
          .substring('lib/'.length)
          .replaceAll(r'\', '/');
      if (allowedFiles.contains(relativePath)) {
        continue;
      }
      if (entity.readAsStringSync().contains('AppServices.instance')) {
        offenders.add(relativePath);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'AppServices.instance must not be referenced outside the '
          'composition root. Use AppScope.servicesOf(context) instead. '
          'Offending files: ${offenders.join(', ')}',
    );
  });
}
