import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
  });

  tearDown(PlatformUtils.debugResetOverrides);

  group('DialogUtils', () {
    testWidgets('shows localized material error dialogs', (tester) async {
      await tester.pumpWidget(
        _DialogTestApp(
          builder: (context) => ElevatedButton(
            onPressed: () => DialogUtils.showErrorDialog(
              context,
              const AppException(AppErrorCode.sessionExpired),
            ),
            child: const Text('Show error'),
          ),
        ),
      );

      await tester.tap(find.text('Show error'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.error), findsOneWidget);
      expect(find.text(l10n.errorSessionExpired), findsOneWidget);

      await tester.tap(find.text(l10n.ok));
      await tester.pumpAndSettle();

      expect(find.text(l10n.errorSessionExpired), findsNothing);
    });

    testWidgets('shows material success messages and dismisses', (
      tester,
    ) async {
      var dismissed = false;

      await tester.pumpWidget(
        _DialogTestApp(
          builder: (context) => ElevatedButton(
            onPressed: () => DialogUtils.showSuccessDialog(
              context,
              'Saved',
              onDismiss: () => dismissed = true,
            ),
            child: const Text('Show success'),
          ),
        ),
      );

      await tester.tap(find.text('Show success'));
      await tester.pump();

      expect(find.text('Saved'), findsOneWidget);
      expect(dismissed, isTrue);
    });

    testWidgets('returns the selected material confirmation result', (
      tester,
    ) async {
      late Future<bool> result;

      await tester.pumpWidget(
        _DialogTestApp(
          builder: (context) => ElevatedButton(
            onPressed: () {
              result = DialogUtils.showConfirmDialog(
                context,
                title: 'Discard recording?',
                message: 'This cannot be undone.',
                confirmText: 'Discard',
                isDestructive: true,
              );
            },
            child: const Text('Show confirm'),
          ),
        ),
      );

      await tester.tap(find.text('Show confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Discard recording?'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(await result, isTrue);
    });

    testWidgets('returns false when material confirmation is canceled', (
      tester,
    ) async {
      late Future<bool> result;

      await tester.pumpWidget(
        _DialogTestApp(
          builder: (context) => ElevatedButton(
            onPressed: () {
              result = DialogUtils.showConfirmDialog(
                context,
                title: 'Logout?',
                message: 'End this session?',
                confirmText: 'Logout',
                isDestructive: true,
              );
            },
            child: const Text('Show confirm'),
          ),
        ),
      );

      await tester.tap(find.text('Show confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(await result, isFalse);
    });

    testWidgets('shows cupertino success dialogs and dismisses', (
      tester,
    ) async {
      PlatformUtils.debugIsApplePlatformOverride = true;
      var dismissed = false;

      await tester.pumpWidget(
        _DialogTestApp(
          builder: (context) => ElevatedButton(
            onPressed: () => DialogUtils.showSuccessDialog(
              context,
              'Saved',
              onDismiss: () => dismissed = true,
            ),
            child: const Text('Show success'),
          ),
        ),
      );

      await tester.tap(find.text('Show success'));
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsOneWidget);
      expect(dismissed, isFalse);

      await tester.tap(find.text(l10n.ok));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('shows material snack bar messages', (tester) async {
      await tester.pumpWidget(
        _DialogTestApp(
          builder: (context) => ElevatedButton(
            onPressed: () => DialogUtils.showMessage(context, 'Logged out'),
            child: const Text('Show message'),
          ),
        ),
      );

      await tester.tap(find.text('Show message'));
      await tester.pump();

      expect(find.text('Logged out'), findsOneWidget);
    });

    testWidgets('honors a custom error dialog title', (tester) async {
      await tester.pumpWidget(
        _DialogTestApp(
          builder: (context) => ElevatedButton(
            onPressed: () => DialogUtils.showErrorDialog(
              context,
              const AppException(AppErrorCode.sessionExpired),
              title: 'Custom title',
            ),
            child: const Text('Show error'),
          ),
        ),
      );

      await tester.tap(find.text('Show error'));
      await tester.pumpAndSettle();

      expect(find.text('Custom title'), findsOneWidget);
      expect(find.text(l10n.error), findsNothing);
    });

    testWidgets('shows cupertino error dialogs', (tester) async {
      PlatformUtils.debugIsApplePlatformOverride = true;

      await tester.pumpWidget(
        _DialogTestApp(
          builder: (context) => ElevatedButton(
            onPressed: () => DialogUtils.showErrorDialog(
              context,
              const AppException(AppErrorCode.sessionExpired),
            ),
            child: const Text('Show error'),
          ),
        ),
      );

      await tester.tap(find.text('Show error'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.errorSessionExpired), findsOneWidget);

      await tester.tap(find.text(l10n.ok));
      await tester.pumpAndSettle();

      expect(find.text(l10n.errorSessionExpired), findsNothing);
    });

    testWidgets('shows cupertino confirmation dialogs', (tester) async {
      PlatformUtils.debugIsApplePlatformOverride = true;
      late Future<bool> result;

      await tester.pumpWidget(
        _DialogTestApp(
          builder: (context) => ElevatedButton(
            onPressed: () {
              result = DialogUtils.showConfirmDialog(
                context,
                title: 'Discard recording?',
                message: 'This cannot be undone.',
                confirmText: 'Discard',
                isDestructive: true,
              );
            },
            child: const Text('Show confirm'),
          ),
        ),
      );

      await tester.tap(find.text('Show confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(await result, isTrue);
    });

    testWidgets('shows cupertino message dialogs', (tester) async {
      PlatformUtils.debugIsApplePlatformOverride = true;

      await tester.pumpWidget(
        _DialogTestApp(
          builder: (context) => ElevatedButton(
            onPressed: () => DialogUtils.showMessage(context, 'Logged out'),
            child: const Text('Show message'),
          ),
        ),
      );

      await tester.tap(find.text('Show message'));
      await tester.pumpAndSettle();

      expect(find.text('Logged out'), findsOneWidget);

      await tester.tap(find.text(l10n.ok));
      await tester.pumpAndSettle();

      expect(find.text('Logged out'), findsNothing);
    });
  });
}

class _DialogTestApp extends StatelessWidget {
  const _DialogTestApp({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Builder(builder: builder)),
    );
  }
}
