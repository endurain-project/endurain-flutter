import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture guard: feature code never reaches the service locator.
///
/// `AppServices` is the composition root and `AppScope` only carries it down to
/// the code that composes screens (`lib/app`). A screen, widget, or controller
/// under `lib/features/` that called `AppScope.servicesOf(context)` could reach
/// any dependency in the app, which hides what it really needs and makes it
/// impossible to build without a full service graph. Features receive their
/// dependencies through constructor parameters; `lib/app/navigation/
/// app_screens.dart` wires them.
void main() {
  final featuresDir = Directory('lib/features');

  final forbidden = RegExp(
    r'AppScope\.(?:servicesOf|maybeServicesOf)|\bAppServices\b|\bAppScope\b',
  );

  test('lib/features never references AppScope or AppServices', () {
    expect(
      featuresDir.existsSync(),
      isTrue,
      reason: 'Test must run from the package root so lib/features resolves.',
    );

    final offenders = <String>[
      for (final entity in featuresDir.listSync(recursive: true))
        if (entity is File && entity.path.endsWith('.dart'))
          for (final match in forbidden.allMatches(entity.readAsStringSync()))
            '${entity.path.replaceAll(r'\', '/')}: ${match.group(0)}',
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'Feature code must take its dependencies as constructor parameters '
          'and let lib/app compose them. Offending references: '
          '${offenders.join(', ')}',
    );
  });
}
