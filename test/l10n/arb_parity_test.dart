import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards translation completeness so new strings cannot ship in only one
/// locale. Every `app_*.arb` catalog is compared against the English template:
/// it must define the exact same message keys (ignoring `@`-prefixed metadata),
/// leave no translation empty, and preserve every `{placeholder}` token.
void main() {
  const arbDir = 'lib/l10n';

  final template = jsonDecode(
    File('$arbDir/app_en.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  final templateKeys = _messageKeys(template);
  final templateTokens = {
    for (final key in templateKeys) key: _tokens(template[key] as String),
  };

  final localeFiles =
      Directory(arbDir)
          .listSync()
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.arb') && !file.path.endsWith('app_en.arb'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('translation catalogs exist beyond the English template', () {
    expect(localeFiles, isNotEmpty);
  });

  for (final file in localeFiles) {
    final name = file.uri.pathSegments.last;

    group(name, () {
      late Map<String, dynamic> arb;
      late Set<String> keys;

      setUpAll(() {
        arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        keys = _messageKeys(arb);
      });

      test('has every English key', () {
        final missing = templateKeys.difference(keys);
        expect(
          missing,
          isEmpty,
          reason: 'Missing translations in $name for: ${missing.join(', ')}',
        );
      });

      test('has no keys absent from English', () {
        final extra = keys.difference(templateKeys);
        expect(
          extra,
          isEmpty,
          reason: '$name defines unknown keys: ${extra.join(', ')}',
        );
      });

      test('leaves no translation empty', () {
        for (final key in keys) {
          expect(
            (arb[key] as String).trim(),
            isNotEmpty,
            reason: 'Empty translation for "$key" in $name',
          );
        }
      });

      test('preserves placeholder tokens', () {
        for (final key in keys.intersection(templateKeys)) {
          expect(
            _tokens(arb[key] as String),
            templateTokens[key],
            reason: 'Placeholder mismatch for "$key" in $name',
          );
        }
      });
    });
  }
}

Set<String> _messageKeys(Map<String, dynamic> arb) {
  return arb.keys.where((key) => !key.startsWith('@')).toSet();
}

/// The set of ICU `{placeholder}` names referenced by a message. The app only
/// uses simple placeholders (no plural/select), so a token scan is sufficient
/// and, unlike reading `@`-metadata, works for lean translation catalogs.
Set<String> _tokens(String message) {
  return RegExp(r'\{(\w+)\}')
      .allMatches(message)
      .map((match) => match.group(1)!)
      .toSet();
}
