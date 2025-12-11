// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:endurain/app.dart';

void main() {
  testWidgets('App loads with bottom navigation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that bottom navigation exists.
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify that Map and Settings tabs exist (2 instances each: one in app bar, one in bottom nav).
    expect(find.text('Map'), findsNWidgets(2));
    expect(find.text('Settings'), findsAtLeastNWidgets(1));
  });
}
