import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/shared/adaptive/adaptive_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(PlatformUtils.debugResetOverrides);

  testWidgets('renders a Material progress indicator by default', (
    tester,
  ) async {
    PlatformUtils.debugIsApplePlatformOverride = false;

    await tester.pumpWidget(const MaterialApp(home: AdaptiveProgressBar()));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
  });

  testWidgets('renders a Cupertino activity indicator on Apple platforms', (
    tester,
  ) async {
    PlatformUtils.debugIsApplePlatformOverride = true;

    await tester.pumpWidget(const MaterialApp(home: AdaptiveProgressBar()));

    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
