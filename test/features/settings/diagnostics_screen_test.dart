import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/settings/diagnostics_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('DiagnosticsScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: DiagnosticsScreen(diagnostics: _FakeDiagnosticsStore()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(l10n.diagnosticsTitle), findsOneWidget);
    expect(find.text(l10n.diagnosticsEmpty), findsOneWidget);
  });

  testWidgets('DiagnosticsScreen empty state is visible on iOS dark mode', (
    tester,
  ) async {
    _useIosDarkMode(tester);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: DiagnosticsScreen(diagnostics: _FakeDiagnosticsStore()),
      ),
    );

    await tester.pumpAndSettle();

    _expectBrightCupertinoText(tester, l10n.diagnosticsEmpty);
  });

  testWidgets('DiagnosticsScreen shows captured report actions', (
    tester,
  ) async {
    final report = DiagnosticsReport.fromPayload({
      'schemaVersion': 1,
      'app': 'Endurain',
      'lastUpdatedAt': '2026-06-01T12:30:00Z',
      'breadcrumbs': [
        {
          'at': '2026-06-01T12:29:00Z',
          'event': DiagnosticsEvents.activityStarted,
          'details': {'activityType': 'walk', 'pointCount': 2},
        },
      ],
      'errors': [
        {
          'at': '2026-06-01T12:30:00Z',
          'source': DiagnosticsSources.flutter,
          'type': 'StateError',
          'message': 'Something failed',
          'stack': 'stack',
        },
      ],
    });

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: DiagnosticsScreen(
          diagnostics: _FakeDiagnosticsStore(report: report),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(l10n.diagnosticsSummary), findsOneWidget);
    expect(find.text(l10n.diagnosticsEventsCount(1)), findsOneWidget);
    expect(find.text(l10n.diagnosticsErrorsCount(1)), findsOneWidget);
    expect(
      find.text(l10n.diagnosticsEventTitle(DiagnosticsEvents.activityStarted)),
      findsOneWidget,
    );
    expect(find.text(l10n.diagnosticsErrorTitle('StateError')), findsOneWidget);
    await _scrollToDiagnosticsActions(tester, l10n);
    expect(find.text(l10n.diagnosticsCopy), findsOneWidget);
    expect(find.text(l10n.diagnosticsClear), findsOneWidget);
    expect(find.textContaining('"breadcrumbs"'), findsOneWidget);
  });

  testWidgets(
    'DiagnosticsScreen raw report spans the same width as other sections on '
    'iOS',
    (tester) async {
      PlatformUtils.debugIsApplePlatformOverride = true;
      addTearDown(PlatformUtils.debugResetOverrides);

      final report = DiagnosticsReport.fromPayload({
        'schemaVersion': 1,
        'app': 'Endurain',
        'lastUpdatedAt': '2026-06-01T12:30:00Z',
        'breadcrumbs': [
          {
            'at': '2026-06-01T12:29:00Z',
            'event': DiagnosticsEvents.activityStarted,
          },
        ],
        'errors': [],
      });

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: DiagnosticsScreen(
            diagnostics: _FakeDiagnosticsStore(report: report),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // A full-width list tile is the reference width for a section's content.
      final copyTileWidth = tester
          .getRect(
            find.ancestor(
              of: find.text(l10n.diagnosticsCopy),
              matching: find.byType(CupertinoListTile),
            ),
          )
          .width;
      final rawReportWidth = tester.getRect(find.byType(SelectableText)).width;

      // The raw report must fill its section like the tiles, not shrink to
      // wrap its monospace text.
      expect(rawReportWidth, greaterThanOrEqualTo(copyTileWidth - 0.5));
    },
  );
}

Future<void> _scrollToDiagnosticsActions(
  WidgetTester tester,
  AppLocalizationsEn l10n,
) async {
  await tester.scrollUntilVisible(
    find.text(l10n.diagnosticsActions),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void _useIosDarkMode(WidgetTester tester) {
  PlatformUtils.debugIsApplePlatformOverride = true;
  tester.binding.platformDispatcher.platformBrightnessTestValue =
      Brightness.dark;
  addTearDown(() {
    PlatformUtils.debugResetOverrides();
    tester.binding.platformDispatcher.clearPlatformBrightnessTestValue();
  });
}

void _expectBrightCupertinoText(WidgetTester tester, String text) {
  final finder = find.text(text);
  final textWidget = tester.widget<Text>(finder);
  final color = textWidget.style?.color;

  expect(color, isNotNull);
  final resolvedColor = CupertinoDynamicColor.resolve(
    color!,
    tester.element(finder),
  );
  expect(resolvedColor.computeLuminance(), greaterThan(0.5));
}

class _FakeDiagnosticsStore implements DiagnosticsStore {
  _FakeDiagnosticsStore({this.report});

  final DiagnosticsReport? report;

  @override
  Future<void> clearReport() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<DiagnosticsReport?> readReport() async => report;

  @override
  Future<String?> readReportText() async => report?.rawText;

  @override
  void recordBreadcrumbSync(
    String event, {
    Map<String, Object?> details = const {},
  }) {}

  @override
  void recordErrorSync(
    Object error,
    StackTrace stackTrace, {
    String source = DiagnosticsSources.uncaught,
  }) {}

  @override
  void recordFlutterErrorSync(FlutterErrorDetails details) {}
}
