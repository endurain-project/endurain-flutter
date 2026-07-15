import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/health/widgets/health_sync_inline_error.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  testWidgets('renders a plain error message verbatim', (tester) async {
    await tester.pumpWidget(
      const TestScaffoldApp(
        child: HealthSyncInlineError(error: 'Something went wrong'),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('renders the localized message for an AppException', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TestScaffoldApp(
        child: HealthSyncInlineError(
          error: AppException(AppErrorCode.healthReadFailed),
        ),
      ),
    );

    final context = tester.element(find.byType(HealthSyncInlineError));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.errorHealthReadFailed), findsOneWidget);
  });
}
