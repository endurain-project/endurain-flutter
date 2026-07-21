import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture guard: the session-mutating auth services and the durable
/// `AuthSessionStore` are constructed only within the auth infrastructure —
/// the composition root's `AuthModule` and the services' own files.
///
/// `AuthSessionStore` serializes every session read/write through a private,
/// per-instance queue. If feature code built a *second* store — directly, or
/// indirectly through a second `AuthService`/`SsoService`/`ApiClient` that
/// derives its own store — for the same secure storage, those writes would no
/// longer serialize against the shared store and a rotating refresh token could
/// be lost. Feature code must therefore obtain these from the composition root
/// via `AppScope.servicesOf(context)` rather than constructing them.
///
/// This complements `app_services_instance_guard_test.dart`: that guard keeps
/// `AppServices` single and injected; this one keeps the auth session single
/// and injected.
void main() {
  final libDir = Directory('lib');

  // Read at collection time (no `expect` here — that would run outside a test
  // body). A missing lib/ surfaces as a clear listSync failure.
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

  // The auth infrastructure files permitted to construct each type: the
  // composition root that wires the single shared instances, each type's own
  // declaration file, and the two services that keep a documented fallback
  // store for standalone (test) construction.
  const allowed = <String, Set<String>>{
    'AuthService': {
      'core/services/auth_service.dart',
      'core/services/api_client.dart',
      'core/services/modules/auth_module.dart',
    },
    'SsoService': {
      'core/services/sso_service.dart',
      'core/services/modules/auth_module.dart',
    },
    'ApiClient': {
      'core/services/api_client.dart',
      'core/services/modules/auth_module.dart',
    },
    'AuthSessionStore': {
      'core/services/auth_session_store.dart',
      'core/services/auth_service.dart',
      'core/services/sso_service.dart',
      'core/services/api_client.dart',
      'core/services/modules/auth_module.dart',
    },
  };

  final files = libDartFiles();

  allowed.forEach((typeName, allowedFiles) {
    test('$typeName is constructed only within the auth infrastructure', () {
      final pattern = RegExp('\\b$typeName\\(');
      final offenders = <String>[
        for (final file in files)
          if (!allowedFiles.contains(file.key) && pattern.hasMatch(file.value))
            file.key,
      ];

      expect(
        offenders,
        isEmpty,
        reason:
            '$typeName must be obtained via AppScope.servicesOf(context) in '
            'feature code, not constructed directly. Constructing a second '
            'AuthSessionStore (directly or via a session-mutating service that '
            'derives its own) breaks session-write serialization. Offending '
            'files: ${offenders.join(', ')}',
      );
    });
  });
}
