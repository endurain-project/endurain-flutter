import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/controllers/local_activity_history_controller.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/screens/activity_history_screen.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
        home: ActivityHistoryScreen(controller: controller),
      ),
    );

    await _pumpUntilFound(tester, find.text(l10n.activityHistoryEmpty));

    expect(find.text(l10n.activityHistoryTitle), findsOneWidget);
    _expectBrightCupertinoText(tester, l10n.activityHistoryEmpty);
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
          home: ActivityHistoryScreen(controller: controller),
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
          home: ActivityHistoryScreen(controller: controller),
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
          home: ActivityHistoryScreen(controller: controller),
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
          home: ActivityHistoryScreen(controller: controller),
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
          home: ActivityHistoryScreen(controller: controller),
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
          home: ActivityHistoryScreen(controller: controller),
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
          home: ActivityHistoryScreen(controller: controller),
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
    testWidgets(
      'load-more button is visible when hasMore is true',
      (tester) async {
        final controller = _LoadedHistoryController(
          records: [_pendingRecord],
          hasMorePages: true,
        );
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          AdaptiveApp(
            title: 'Test',
            home: ActivityHistoryScreen(controller: controller),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(l10n.activityHistoryLoadMore), findsOneWidget);
      },
    );

    testWidgets(
      'load-more button is hidden when hasMore is false',
      (tester) async {
        final controller = _LoadedHistoryController(
          records: [_pendingRecord],
          hasMorePages: false,
        );
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          AdaptiveApp(
            title: 'Test',
            home: ActivityHistoryScreen(controller: controller),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(l10n.activityHistoryLoadMore), findsNothing);
      },
    );

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
          home: ActivityHistoryScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.activityHistoryLoadMore));
      await tester.pumpAndSettle();

      expect(loadMoreCallCount, 1);
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
      );

  @override
  List<LocalActivityRecord> get records => const [];

  @override
  bool get isLoading => false;

  @override
  Object? get error => null;

  @override
  bool get hasMore => false;

  @override
  Future<void> load() async {}
}

class _LoadedHistoryController extends LocalActivityHistoryController {
  _LoadedHistoryController({
    required List<LocalActivityRecord> records,
    this.hasMorePages = false,
    this.loadMoreCallback,
  }) : _records = records,
       super(
         repository: LocalActivityRepository(
           supportDirectoryProvider: () async => throw StateError('unused'),
         ),
         uploadService: ActivityUploadService(),
       );

  final List<LocalActivityRecord> _records;
  final bool hasMorePages;
  final Future<void> Function()? loadMoreCallback;

  @override
  List<LocalActivityRecord> get records => _records;

  @override
  bool get isLoading => false;

  @override
  Object? get error => null;

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
      );

  @override
  List<LocalActivityRecord> get records => const [];

  @override
  bool get isLoading => false;

  @override
  Object? get error => StateError('load failed');

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
      );

  @override
  List<LocalActivityRecord> get records => const [];

  @override
  bool get isLoading => true;

  @override
  Object? get error => null;

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
