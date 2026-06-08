import 'package:endurain/features/activity/controllers/local_activity_history_controller.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/screens/activity_details_screen.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter_test/flutter_test.dart';

final _l10n = AppLocalizationsEn();

final _baseRecord = LocalActivityRecord(
  id: 'rec-1',
  activityType: ActivityType.run,
  startedAt: DateTime.utc(2024, 1, 1, 8),
  endedAt: DateTime.utc(2024, 1, 1, 9),
  elapsedDurationSeconds: 3661,
  distanceMeters: 5000.0,
  averageSpeedMetersPerSecond: 2.5,
  pointCount: 200,
  gpxFileName: 'rec-1.gpx',
  uploadStatus: LocalActivityUploadStatus.pending,
  createdAt: DateTime.utc(2024, 1, 1),
  updatedAt: DateTime.utc(2024, 1, 1),
);

// ---------------------------------------------------------------------------
// Phase 14 — loading and missing states
// ---------------------------------------------------------------------------

void main() {
  group('ActivityDetailsScreen – Phase 14: loading/missing states', () {
    testWidgets('loading state shows AdaptiveLoadingIndicator', (tester) async {
      final controller = _LoadingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityDetailsScreen(
            recordId: 'rec-1',
            controller: controller,
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(AdaptiveLoadingIndicator), findsOneWidget);
      expect(find.text(_l10n.activityHistoryDetailsMissing), findsNothing);
    });

    testWidgets('missing record shows activityHistoryDetailsMissing', (
      tester,
    ) async {
      final controller = _MissingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AdaptiveApp(
          title: 'Test',
          home: ActivityDetailsScreen(
            recordId: 'rec-1',
            controller: controller,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(_l10n.activityHistoryDetailsMissing), findsOneWidget);
      expect(find.byType(AdaptiveLoadingIndicator), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Phase 15 — summary section
  // -------------------------------------------------------------------------

  group('ActivityDetailsScreen – Phase 15: summary section', () {
    testWidgets('shows activity type label', (tester) async {
      final controller = _LoadedController(record: _baseRecord);
      addTearDown(controller.dispose);

      await _pumpDetails(tester, controller);

      expect(find.text(_l10n.activityTypeRun), findsOneWidget);
    });

    testWidgets('shows formatted duration', (tester) async {
      final controller = _LoadedController(record: _baseRecord);
      addTearDown(controller.dispose);

      await _pumpDetails(tester, controller);

      // 3661 seconds → 1:01:01
      expect(find.text('1:01:01'), findsOneWidget);
    });

    testWidgets('shows point count', (tester) async {
      final controller = _LoadedController(record: _baseRecord);
      addTearDown(controller.dispose);

      await _pumpDetails(tester, controller);

      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('shows upload status pending', (tester) async {
      final controller = _LoadedController(record: _baseRecord);
      addTearDown(controller.dispose);

      await _pumpDetails(tester, controller);

      expect(find.text(_l10n.activityUploadStatusPending), findsOneWidget);
    });

    testWidgets('shows upload status uploaded', (tester) async {
      final record = LocalActivityRecord(
        id: _baseRecord.id,
        activityType: _baseRecord.activityType,
        startedAt: _baseRecord.startedAt,
        endedAt: _baseRecord.endedAt,
        elapsedDurationSeconds: _baseRecord.elapsedDurationSeconds,
        distanceMeters: _baseRecord.distanceMeters,
        pointCount: _baseRecord.pointCount,
        gpxFileName: _baseRecord.gpxFileName,
        uploadStatus: LocalActivityUploadStatus.uploaded,
        createdAt: _baseRecord.createdAt,
        updatedAt: _baseRecord.updatedAt,
      );
      final controller = _LoadedController(record: record);
      addTearDown(controller.dispose);

      await _pumpDetails(tester, controller);

      expect(find.text(_l10n.activityUploadStatusUploaded), findsOneWidget);
    });

    testWidgets('shows GPX available when hasGpx is true', (tester) async {
      final controller = _LoadedController(
        record: _baseRecord,
        hasGpxValue: true,
      );
      addTearDown(controller.dispose);

      await _pumpDetails(tester, controller);

      expect(find.text(_l10n.activityHistoryGpxAvailable), findsOneWidget);
    });

    testWidgets('shows GPX missing when hasGpx is false', (tester) async {
      final controller = _LoadedController(record: _baseRecord);
      addTearDown(controller.dispose);

      await _pumpDetails(tester, controller);

      expect(find.text(_l10n.activityHistoryGpxMissing), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Phase 16 — action section
  // -------------------------------------------------------------------------

  group('ActivityDetailsScreen – Phase 16: actions section', () {
    testWidgets('retry and delete actions shown for pending upload', (
      tester,
    ) async {
      final controller = _LoadedController(record: _baseRecord);
      addTearDown(controller.dispose);

      await _pumpDetails(tester, controller);

      expect(find.text(_l10n.activityRetryUpload), findsOneWidget);
      expect(find.text(_l10n.activityDeleteLocal), findsOneWidget);
    });

    testWidgets('retry action hidden for uploaded record', (tester) async {
      final record = LocalActivityRecord(
        id: _baseRecord.id,
        activityType: _baseRecord.activityType,
        startedAt: _baseRecord.startedAt,
        endedAt: _baseRecord.endedAt,
        elapsedDurationSeconds: _baseRecord.elapsedDurationSeconds,
        distanceMeters: _baseRecord.distanceMeters,
        pointCount: _baseRecord.pointCount,
        gpxFileName: _baseRecord.gpxFileName,
        uploadStatus: LocalActivityUploadStatus.uploaded,
        createdAt: _baseRecord.createdAt,
        updatedAt: _baseRecord.updatedAt,
      );
      final controller = _LoadedController(record: record);
      addTearDown(controller.dispose);

      await _pumpDetails(tester, controller);

      expect(find.text(_l10n.activityRetryUpload), findsNothing);
      expect(find.text(_l10n.activityDeleteLocal), findsOneWidget);
    });

    testWidgets(
      'busy state shows loading indicator in actions and hides buttons',
      (tester) async {
        final controller = _LoadedController(record: _baseRecord, busy: true);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          AdaptiveApp(
            title: 'Test',
            home: ActivityDetailsScreen(
              recordId: _baseRecord.id,
              controller: controller,
            ),
          ),
        );
        // Pump a few frames — avoid pumpAndSettle due to continuous animation.
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text(_l10n.activityRetryUpload), findsNothing);
        expect(find.text(_l10n.activityDeleteLocal), findsNothing);
        expect(find.byType(AdaptiveLoadingIndicator), findsOneWidget);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> _pumpDetails(
  WidgetTester tester,
  LocalActivityHistoryController controller,
) async {
  await tester.pumpWidget(
    AdaptiveApp(
      title: 'Test',
      home: ActivityDetailsScreen(
        recordId: _baseRecord.id,
        controller: controller,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Fake controllers
// ---------------------------------------------------------------------------

class _LoadingController extends LocalActivityHistoryController {
  _LoadingController()
    : super(
        repository: LocalActivityRepository(
          supportDirectoryProvider: () async => throw StateError('unused'),
        ),
        uploadService: ActivityUploadService(),
      );

  @override
  bool get isLoading => true;

  @override
  LocalActivityRecord? recordById(String id) => null;

  @override
  Future<bool> hasGpx(LocalActivityRecord record) async => false;

  @override
  Future<void> load() async {}
}

class _MissingController extends LocalActivityHistoryController {
  _MissingController()
    : super(
        repository: LocalActivityRepository(
          supportDirectoryProvider: () async => throw StateError('unused'),
        ),
        uploadService: ActivityUploadService(),
      );

  @override
  bool get isLoading => false;

  @override
  LocalActivityRecord? recordById(String id) => null;

  @override
  Future<bool> hasGpx(LocalActivityRecord record) async => false;

  @override
  Future<void> load() async {}
}

class _LoadedController extends LocalActivityHistoryController {
  _LoadedController({
    required this.record,
    this.hasGpxValue = false,
    bool busy = false,
  }) : _busy = busy,
       super(
         repository: LocalActivityRepository(
           supportDirectoryProvider: () async => throw StateError('unused'),
         ),
         uploadService: ActivityUploadService(),
       );

  final LocalActivityRecord record;
  final bool hasGpxValue;
  final bool _busy;

  @override
  bool get isLoading => false;

  @override
  LocalActivityRecord? recordById(String id) => id == record.id ? record : null;

  @override
  bool isBusy(String id) => _busy && id == record.id;

  @override
  Future<bool> hasGpx(LocalActivityRecord r) async => hasGpxValue;

  @override
  Future<void> load() async {}
}
