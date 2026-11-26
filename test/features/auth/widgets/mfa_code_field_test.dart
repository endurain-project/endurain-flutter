import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/auth/widgets/mfa_code_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  tearDown(PlatformUtils.debugResetOverrides);

  for (final apple in [false, true]) {
    testWidgets('shows each typed character in its own box '
        '(${apple ? 'Apple' : 'Material'})', (tester) async {
      PlatformUtils.debugIsApplePlatformOverride = apple;
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        TestScaffoldApp(
          child: MfaCodeField(
            controller: controller,
            kind: MfaCodeKind.backupCode,
            label: 'Backup code',
            instruction: 'Enter a backup code',
          ),
        ),
      );
      await tester.enterText(
        find.byType(apple ? CupertinoTextField : TextField),
        'a3k9-7bdf',
      );
      await tester.pump();

      expect(controller.text, 'A3K97BDF');
      for (final character in 'A3K97BDF'.split('')) {
        expect(find.text(character), findsWidgets);
      }
      expect(find.text('Enter a backup code'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reports a completed code once per completion', (tester) async {
    PlatformUtils.debugIsApplePlatformOverride = false;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var completed = 0;

    await tester.pumpWidget(
      TestScaffoldApp(
        child: MfaCodeField(
          controller: controller,
          kind: MfaCodeKind.totp,
          label: 'MFA code',
          instruction: 'Enter the code',
          onCompleted: () => completed++,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();
    expect(completed, 0);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(completed, 1);

    // Extra digits are dropped and do not send the code again.
    await tester.enterText(find.byType(TextField), '1234567');
    await tester.pump();
    expect(completed, 1);

    // Deleting a digit and typing it again completes the code anew.
    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '123459');
    await tester.pump();
    expect(completed, 2);
  });

  group('MfaCodeKind.totp', () {
    test('keeps only the first six digits', () {
      expect(MfaCodeKind.totp.normalize('12a3 45-6789'), '123456');
      expect(MfaCodeKind.totp.normalize('abc'), isEmpty);
    });

    test('is sent as typed', () {
      expect(MfaCodeKind.totp.toSubmission('123 456'), '123456');
    });
  });

  group('MfaCodeKind.backupCode', () {
    test('keeps eight letters and digits, uppercased', () {
      expect(MfaCodeKind.backupCode.normalize('a3k9-7bdf-xyz'), 'A3K97BDF');
      expect(MfaCodeKind.backupCode.normalize(' a3 k9 '), 'A3K9');
    });

    test('is sent as XXXX-XXXX', () {
      expect(MfaCodeKind.backupCode.toSubmission('a3k97bdf'), 'A3K9-7BDF');
      expect(MfaCodeKind.backupCode.toSubmission('A3K9-7BDF'), 'A3K9-7BDF');
    });

    test('an incomplete code gets no dash', () {
      expect(MfaCodeKind.backupCode.toSubmission('A3K97'), 'A3K97');
    });
  });
}
