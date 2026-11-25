import 'package:endurain/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The countdown length presets (3 to 30 seconds) need the right plural form
/// in languages where "3 seconds" and "5 seconds" differ.
void main() {
  String label(String locale, int seconds) =>
      lookupAppLocalizations(Locale(locale))
          .startCountdownDurationOptionLabel(seconds);

  test('uses the few form for three seconds', () {
    expect(label('hr', 3), '3 sekunde');
    expect(label('sr', 3), '3 секунде');
    expect(label('cs', 3), '3 sekundy');
    expect(label('sk', 3), '3 sekundy');
    expect(label('sl', 3), '3 sekunde');
    expect(label('ro', 3), '3 secunde');
  });

  test('uses the other form for the longer presets', () {
    expect(label('hr', 5), '5 sekundi');
    expect(label('sr', 10), '10 секунди');
    expect(label('cs', 5), '5 sekund');
    expect(label('sk', 15), '15 sekúnd');
    expect(label('sl', 5), '5 sekund');
    expect(label('ro', 30), '30 de secunde');
  });

  test('keeps the plain form elsewhere', () {
    expect(label('en', 3), '3 seconds');
    expect(label('pt', 3), '3 segundos');
  });
}
