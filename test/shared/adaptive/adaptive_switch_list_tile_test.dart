import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const subtitle =
      'Send crash and error reports to a diagnostics server. This is separate '
      'from local diagnostics, so either setting can be enabled independently.';

  for (final isApplePlatform in [false, true]) {
    final platformName = isApplePlatform ? 'Cupertino' : 'Material';

    testWidgets('$platformName switch subtitle shows its full text', (
      tester,
    ) async {
      PlatformUtils.debugIsApplePlatformOverride = isApplePlatform;
      addTearDown(PlatformUtils.debugResetOverrides);

      await _pumpTile(
        tester,
        isApplePlatform: isApplePlatform,
        child: AdaptiveSwitchListTile(
          title: 'Send crash reports',
          subtitle: subtitle,
          leading: const Icon(Icons.cloud_upload_outlined),
          value: true,
          onChanged: (_) {},
        ),
      );

      _expectFullSubtitle(tester, subtitle);
    });

    testWidgets('$platformName list subtitle shows its full text', (
      tester,
    ) async {
      PlatformUtils.debugIsApplePlatformOverride = isApplePlatform;
      addTearDown(PlatformUtils.debugResetOverrides);

      await _pumpTile(
        tester,
        isApplePlatform: isApplePlatform,
        child: const AdaptiveListTile(
          title: 'Diagnostics',
          subtitle: subtitle,
          leading: Icon(Icons.bug_report_outlined),
        ),
      );

      _expectFullSubtitle(tester, subtitle);
    });

    testWidgets('$platformName checkbox subtitle shows its full text', (
      tester,
    ) async {
      PlatformUtils.debugIsApplePlatformOverride = isApplePlatform;
      addTearDown(PlatformUtils.debugResetOverrides);

      await _pumpTile(
        tester,
        isApplePlatform: isApplePlatform,
        child: AdaptiveCheckboxListTile(
          value: true,
          title: const Text('Import workout'),
          subtitle: const Text(subtitle),
          secondary: const Icon(Icons.fitness_center),
          onChanged: (_) {},
        ),
      );

      _expectFullSubtitle(tester, subtitle);
    });
  }
}

Future<void> _pumpTile(
  WidgetTester tester, {
  required bool isApplePlatform,
  required Widget child,
}) async {
  final tile = SizedBox(width: 320, child: child);

  await tester.pumpWidget(
    isApplePlatform
        ? CupertinoApp(
            home: CupertinoPageScaffold(child: Center(child: tile)),
          )
        : MaterialApp(
            home: Scaffold(body: Center(child: tile)),
          ),
  );
}

void _expectFullSubtitle(WidgetTester tester, String subtitle) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(subtitle));
  expect(paragraph.didExceedMaxLines, isFalse);
  expect(tester.takeException(), isNull);
}
