import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/models/activity_upload_state.dart';
import 'package:endurain/features/activity/widgets/activity_upload_status_panel.dart';
import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityUploadStatusPanel', () {
    testWidgets('shows uploading state without actions', (tester) async {
      await tester.pumpWidget(
        const _TestApp(
          child: ActivityUploadStatusPanel(
            status: ActivityUploadStatus.uploading,
            error: null,
            onRetry: null,
            onDone: null,
            onDelete: null,
          ),
        ),
      );

      expect(find.text(AppLocalizationsEn().activityUploading), findsOneWidget);
      expect(find.text(AppLocalizationsEn().activityRetryUpload), findsNothing);
      expect(find.text(AppLocalizationsEn().activityDone), findsNothing);
      expect(find.text(AppLocalizationsEn().activityDeleteLocal), findsNothing);
    });

    testWidgets('shows uploaded state with non-destructive done action', (
      tester,
    ) async {
      var done = false;
      var viewedHistory = false;
      var deleted = false;

      await tester.pumpWidget(
        _TestApp(
          child: ActivityUploadStatusPanel(
            status: ActivityUploadStatus.uploaded,
            error: null,
            onRetry: null,
            onDone: () => done = true,
            onDelete: () => deleted = true,
            onViewHistory: () => viewedHistory = true,
          ),
        ),
      );

      expect(find.text(AppLocalizationsEn().activityUploaded), findsOneWidget);
      expect(find.text(AppLocalizationsEn().activityDone), findsOneWidget);
      expect(
        find.text(AppLocalizationsEn().activityViewHistory),
        findsOneWidget,
      );
      expect(
        find.text(AppLocalizationsEn().activityDeleteLocal),
        findsOneWidget,
      );

      await tester.tap(find.text(AppLocalizationsEn().activityDone));
      await tester.tap(find.text(AppLocalizationsEn().activityViewHistory));
      await tester.tap(find.text(AppLocalizationsEn().activityDeleteLocal));

      expect(done, isTrue);
      expect(viewedHistory, isTrue);
      expect(deleted, isTrue);
    });

    testWidgets('shows failed state with retry and delete actions', (
      tester,
    ) async {
      var retried = false;
      var deleted = false;

      await tester.pumpWidget(
        _TestApp(
          child: ActivityUploadStatusPanel(
            status: ActivityUploadStatus.failed,
            error: const AppException(AppErrorCode.activityUploadNotConfigured),
            onRetry: () => retried = true,
            onDone: null,
            onDelete: () => deleted = true,
          ),
        ),
      );

      expect(
        find.text(AppLocalizationsEn().activityUploadFailed),
        findsOneWidget,
      );
      expect(
        find.text(AppLocalizationsEn().errorActivityUploadNotConfigured),
        findsOneWidget,
      );

      await tester.tap(find.text(AppLocalizationsEn().activityRetryUpload));
      await tester.tap(find.text(AppLocalizationsEn().activityDeleteLocal));

      expect(retried, isTrue);
      expect(deleted, isTrue);
    });

    testWidgets('shows cleanup failure without retry action', (tester) async {
      var deleted = false;

      await tester.pumpWidget(
        _TestApp(
          child: ActivityUploadStatusPanel(
            status: ActivityUploadStatus.cleanupFailed,
            error: const AppException(AppErrorCode.activityLocalDeleteFailed),
            onRetry: () {},
            onDone: null,
            onDelete: () => deleted = true,
          ),
        ),
      );

      expect(
        find.text(AppLocalizationsEn().activityUploadCleanupFailed),
        findsOneWidget,
      );
      expect(
        find.text(AppLocalizationsEn().errorActivityLocalDeleteFailed),
        findsOneWidget,
      );
      expect(find.text(AppLocalizationsEn().activityRetryUpload), findsNothing);

      await tester.tap(find.text(AppLocalizationsEn().activityDeleteLocal));

      expect(deleted, isTrue);
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}
