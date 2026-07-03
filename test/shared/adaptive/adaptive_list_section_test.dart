import 'dart:io';

import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Cupertino section paints a transparent background so the scaffold shows '
    'through the rounded corners',
    (tester) async {
      PlatformUtils.debugIsApplePlatformOverride = true;
      addTearDown(PlatformUtils.debugResetOverrides);

      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: AdaptiveListSection(
              children: [AdaptiveListTile(title: 'Server URL')],
            ),
          ),
        ),
      );

      final section = tester.widget<CupertinoListSection>(
        find.byType(CupertinoListSection),
      );
      // An opaque background (the default is pure black in dark mode) shows
      // through the square area outside the card's corner radius as black
      // "tips"; transparent lets the scaffold background show instead.
      expect(section.backgroundColor, CupertinoColors.transparent);
    },
  );

  testWidgets(
    'Cupertino section aligns with form field width',
    (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
            width: 390,
            height: 320,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                AdaptiveListSection(
                  header: 'Logged in',
                  children: [AdaptiveListTile(title: 'Server URL')],
                ),
                SizedBox(height: 16),
                AdaptiveTextFormField(
                  label: 'Map tile server URL',
                  placeholder: 'https://example.com',
                ),
              ],
            ),
          ),
        ),
      );

      final sectionTileRect = tester.getRect(find.byType(CupertinoListTile));
      final fieldRect = tester.getRect(find.byType(CupertinoTextFormFieldRow));
      final headerRect = tester.getRect(find.text('Logged in'));

      expect(headerRect.left, fieldRect.left);
      expect(sectionTileRect.left, fieldRect.left);
      expect(sectionTileRect.right, fieldRect.right);
    },
    skip: !Platform.isMacOS && !Platform.isIOS,
  );
}
