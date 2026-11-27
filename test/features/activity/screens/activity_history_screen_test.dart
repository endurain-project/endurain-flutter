import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/platform/url_launcher_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/controllers/local_activity_history_controller.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/screens/activity_history_screen.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fake_preferences_store.dart';
import '../../../helpers/fake_share_service.dart';

void main() {
  final l10n = AppLocalizationsEn();

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
  });

  tearDown(PlatformUtils.debugResetOverrides);

  testWidgets('ActivityHistoryScreen empty state is visible on iOS dark mode', (
    tester,
  ) async {
    _useIosDarkMode(tester);
    final controller = _LoadedEmptyHistoryController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: ActivityHistoryScreen(
          urlLauncher: const UrlLauncherService(),
          controller: controller,
        ),
      ),
    );

    await _pumpUntilFound(tester, find.text(l10n.activityHistoryEmpty));

    expect(find.text(l10n.activityHistoryTitle), findsOneWidget);
    _expectBrightCupertinoText(tester, l10n.activityHistoryEmpty);
  });

  group('ActivityHistoryScreen – GPX retention switch', () {
    testWidgets('shows the switch above an empty history', (tester) async {
      final retention = _FakeRetentionSettings()..retainUploadedGpx = false;
      final controller = _RetentionHistoryController(retention);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.activityRetainUploadedGpx), findsOneWidget);
      expect(find.text(l10n.activityHistoryEmpty), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(l10n.activityRetainUploadedGpx)).dy,
        lessThan(tester.getTopLeft(find.text(l10n.activityHistoryEmpty)).dy),
      );
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('toggling the switch saves the preference', (tester) async {
      final retention = _FakeRetentionSettings();
      final controller = _RetentionHistoryController(retention);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(retention.retainUploadedGpx, isFalse);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('hides the switch without a retention repository', (
      tester,
    ) async {
      final controller = _LoadedEmptyHistoryController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.activityRetainUploadedGpx), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Phase 17 — populated list
  // -------------------------------------------------------------------------

  group('ActivityHistoryScreen – Phase 17: populated list', () {
    testWidgets('populated list shows section header', (tester) async {
      final controller = _LoadedHistoryController(records: [_pendingRecord]);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.activityHistoryLocalActivities), findsOneWidget);
    });

    testWidgets('populated list shows activity type in tile', (tester) async {
      final controller = _LoadedHistoryController(records: [_pendingRecord]);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining(l10n.activityTypeRun), findsOneWidget);
    });

    testWidgets('uploaded record shows cloud-done icon', (tester) async {
      final controller = _LoadedHistoryController(records: [_uploadedRecord]);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Phase 18 — error / loading states
  // -------------------------------------------------------------------------

  group('ActivityHistoryScreen – Phase 18: error/loading states', () {
    testWidgets('error state shows load-failed message and refresh', (
      tester,
    ) async {
      final controller = _ErrorHistoryController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.activityHistoryLoadFailed), findsOneWidget);
      expect(find.text(l10n.activityHistoryRefresh), findsOneWidget);
    });

    testWidgets('loading state shows AdaptiveLoadingIndicator', (tester) async {
      final controller = _LoadingHistoryController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      // Pump a few frames — avoid pumpAndSettle due to continuous animation.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(AdaptiveLoadingIndicator), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Phase 19 — per-tile delete / retry actions
  // -------------------------------------------------------------------------

  group('ActivityHistoryScreen – Phase 19: tile actions', () {
    testWidgets('pending record shows retry and delete buttons', (
      tester,
    ) async {
      final controller = _LoadedHistoryController(records: [_pendingRecord]);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_findIconButton(tester, l10n.activityRetryUpload), findsOneWidget);
      expect(_findIconButton(tester, l10n.activityDeleteLocal), findsOneWidget);
    });

    testWidgets('uploaded record hides retry button', (tester) async {
      final controller = _LoadedHistoryController(records: [_uploadedRecord]);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_findIconButton(tester, l10n.activityRetryUpload), findsNothing);
      expect(_findIconButton(tester, l10n.activityDeleteLocal), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Phase 8 — load-more affordance
  // -------------------------------------------------------------------------

  group('ActivityHistoryScreen – Phase 8: load more', () {
    testWidgets('load-more button is visible when hasMore is true', (
      tester,
    ) async {
      final controller = _LoadedHistoryController(
        records: [_pendingRecord],
        hasMorePages: true,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.activityHistoryLoadMore), findsOneWidget);
    });

    testWidgets('load-more button is hidden when hasMore is false', (
      tester,
    ) async {
      final controller = _LoadedHistoryController(
        records: [_pendingRecord],
        hasMorePages: false,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.activityHistoryLoadMore), findsNothing);
    });

    testWidgets('tapping load-more calls loadMore on controller', (
      tester,
    ) async {
      var loadMoreCallCount = 0;
      final controller = _LoadedHistoryController(
        records: [_pendingRecord],
        hasMorePages: true,
        loadMoreCallback: () async => loadMoreCallCount++,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.activityHistoryLoadMore));
      await tester.pumpAndSettle();

      expect(loadMoreCallCount, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Large screens (e.g. an unfolded iPhone Duo)
  // -------------------------------------------------------------------------

  group('ActivityHistoryScreen – side-by-side details', () {
    // An unfolded iPhone Duo: 669pt wide in portrait, 951pt in landscape.
    const portrait = Size(669, 951);
    const landscape = Size(951, 669);

    void setWindowSize(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
    }

    Future<void> pumpHistory(WidgetTester tester) async {
      final controller = _LoadedHistoryController(
        records: [_pendingRecord, _uploadedRecord],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityHistoryScreen(
            urlLauncher: const UrlLauncherService(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a narrow window shows only the list', (tester) async {
      setWindowSize(tester, portrait);
      addTearDown(tester.view.reset);
      await pumpHistory(tester);

      expect(find.text(l10n.activityHistorySummary), findsNothing);

      await tester.tap(
        find.textContaining(l10n.activityHistoryDuration('')).first,
      );
      await tester.pumpAndSettle();

      // Tapping a record opens its own page.
      expect(find.text(l10n.activityHistoryDetailsTitle), findsOneWidget);
      expect(find.text(l10n.activityHistorySummary), findsOneWidget);
    });

    testWidgets('a wide window shows the first record beside the list', (
      tester,
    ) async {
      setWindowSize(tester, landscape);
      addTearDown(tester.view.reset);
      await pumpHistory(tester);

      expect(find.text(l10n.activityHistoryLocalActivities), findsOneWidget);
      expect(find.text(l10n.activityHistorySummary), findsOneWidget);
      expect(find.text('${_pendingRecord.pointCount}'), findsOneWidget);
      // The pane has no navigation bar of its own.
      expect(find.text(l10n.activityHistoryDetailsTitle), findsNothing);
    });

    testWidgets('tapping a record shows it in the pane instead of a page', (
      tester,
    ) async {
      setWindowSize(tester, landscape);
      addTearDown(tester.view.reset);
      await pumpHistory(tester);

      await tester.tap(
        find.textContaining(l10n.activityHistoryDuration('')).last,
      );
      await tester.pumpAndSettle();

      expect(find.text('${_uploadedRecord.pointCount}'), findsOneWidget);
      expect(find.text('${_pendingRecord.pointCount}'), findsNothing);
      expect(find.text(l10n.activityHistoryDetailsTitle), findsNothing);
    });

    testWidgets('only the list uses the primary scroll controller', (
      tester,
    ) async {
      setWindowSize(tester, landscape);
      addTearDown(tester.view.reset);
      await pumpHistory(tester);

      // The status bar tap and keyboard paging drive this controller, which
      // fails with more than one scroll view attached.
      final listContext = tester.element(find.byType(ListView).first);
      expect(PrimaryScrollController.of(listContext).positions, hasLength(1));
    });

    testWidgets('folding back to a narrow window keeps the list', (
      tester,
    ) async {
      setWindowSize(tester, landscape);
      addTearDown(tester.view.reset);
      await pumpHistory(tester);
      expect(find.text(l10n.activityHistorySummary), findsOneWidget);

      setWindowSize(tester, portrait);
      await tester.pumpAndSettle();

      expect(find.text(l10n.activityHistoryLocalActivities), findsOneWidget);
      expect(find.text(l10n.activityHistorySummary), findsNothing);
    });
  });
}

// ---------------------------------------------------------------------------
// Shared test records
// ---------------------------------------------------------------------------

final _pendingRecord = LocalActivityRecord(
  id: 'rec-1',
  activityType: ActivityType.run,
  startedAt: DateTime.utc(2024, 1, 1, 8),
  endedAt: DateTime.utc(2024, 1, 1, 9),
  elapsedDurationSeconds: 3661,
  distanceMeters: 5000.0,
  pointCount: 200,
  gpxFileName: 'rec-1.gpx',
  uploadStatus: LocalActivityUploadStatus.pending,
  createdAt: DateTime.utc(2024, 1, 1),
  updatedAt: DateTime.utc(2024, 1, 1),
);

final _uploadedRecord = LocalActivityRecord(
  id: 'rec-2',
  activityType: ActivityType.run,
  startedAt: DateTime.utc(2024, 1, 2, 8),
  endedAt: DateTime.utc(2024, 1, 2, 9),
  elapsedDurationSeconds: 1800,
  distanceMeters: 3000.0,
  pointCount: 150,
  gpxFileName: 'rec-2.gpx',
  uploadStatus: LocalActivityUploadStatus.uploaded,
  createdAt: DateTime.utc(2024, 1, 2),
  updatedAt: DateTime.utc(2024, 1, 2),
);

// ---------------------------------------------------------------------------
// Fake controllers
// ---------------------------------------------------------------------------

class _LoadedEmptyHistoryController extends LocalActivityHistoryController {
  _LoadedEmptyHistoryController()
    : super(
        repository: LocalActivityRepository(
          supportDirectoryProvider: () async => throw StateError('unused'),
        ),
        uploadService: ActivityUploadService(),
        shareService: FakeShareService(),
      );

  @override
  List<LocalActivityRecord> get records => const [];

  @override
  bool get isLoading => false;

  @override
  AppException? get error => null;

  @override
  bool get hasMore => false;

  @override
  Future<void> load() async {}
}

class _LoadedHistoryController extends LocalActivityHistoryController {
  _LoadedHistoryController({
    required this._records,
    this.hasMorePages = false,
    this.loadMoreCallback,
  }) : super(
         repository: LocalActivityRepository(
           supportDirectoryProvider: () async => throw StateError('unused'),
         ),
         uploadService: ActivityUploadService(),
         shareService: FakeShareService(),
       );

  final List<LocalActivityRecord> _records;
  final bool hasMorePages;
  final Future<void> Function()? loadMoreCallback;

  @override
  List<LocalActivityRecord> get records => _records;

  @override
  LocalActivityRecord? recordById(String id) =>
      _records.where((record) => record.id == id).firstOrNull;

  @override
  bool get isLoading => false;

  @override
  AppException? get error => null;

  @override
  bool get hasMore => hasMorePages;

  @override
  Future<void> load() async {}

  @override
  Future<void> loadMore() async => loadMoreCallback?.call();
}

class _ErrorHistoryController extends LocalActivityHistoryController {
  _ErrorHistoryController()
    : super(
        repository: LocalActivityRepository(
          supportDirectoryProvider: () async => throw StateError('unused'),
        ),
        uploadService: ActivityUploadService(),
        shareService: FakeShareService(),
      );

  @override
  List<LocalActivityRecord> get records => const [];

  @override
  bool get isLoading => false;

  @override
  AppException? get error =>
      const AppException(AppErrorCode.activityLocalLoadFailed);

  @override
  bool get hasMore => false;

  @override
  Future<void> load() async {}
}

class _LoadingHistoryController extends LocalActivityHistoryController {
  _LoadingHistoryController()
    : super(
        repository: LocalActivityRepository(
          supportDirectoryProvider: () async => throw StateError('unused'),
        ),
        uploadService: ActivityUploadService(),
        shareService: FakeShareService(),
      );

  @override
  List<LocalActivityRecord> get records => const [];

  @override
  bool get isLoading => true;

  @override
  AppException? get error => null;

  @override
  bool get hasMore => false;

  @override
  Future<void> load() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Finder _findIconButton(WidgetTester tester, String tooltip) {
  return find.byWidgetPredicate((w) => w is IconButton && w.tooltip == tooltip);
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  expect(finder, findsOneWidget);
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

/// Empty history whose `load` reads a real retention preference, so the
/// switch can be exercised without a database.
class _RetentionHistoryController extends LocalActivityHistoryController {
  _RetentionHistoryController(ActivityRetentionSettingsRepository retention)
    : super(
        repository: LocalActivityRepository(
          supportDirectoryProvider: () async => throw StateError('unused'),
        ),
        uploadService: ActivityUploadService(),
        shareService: FakeShareService(),
        retentionSettingsRepository: retention,
      );

  @override
  List<LocalActivityRecord> get records => const [];

  @override
  bool get isLoading => false;

  @override
  AppException? get error => null;

  @override
  bool get hasMore => false;
}

class _FakeRetentionSettings extends ActivityRetentionSettingsRepository {
  _FakeRetentionSettings() : super(preferences: FakePreferencesStore());

  bool retainUploadedGpx = true;

  @override
  Future<bool> isRetainUploadedGpxEnabled() async => retainUploadedGpx;

  @override
  Future<void> setRetainUploadedGpxEnabled(bool enabled) async {
    retainUploadedGpx = enabled;
  }
}
