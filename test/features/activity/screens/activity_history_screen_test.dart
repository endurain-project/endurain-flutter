import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/controllers/local_activity_history_controller.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/screens/activity_history_screen.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

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
}

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
  Future<void> load() async {}
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
