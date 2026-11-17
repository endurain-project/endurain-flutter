import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/account_migration/services/legacy_profile_adoption_service.dart';
import 'package:endurain/features/account_migration/widgets/legacy_profile_adoption_dialog.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final l10n = AppLocalizationsEn();

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
  });

  tearDown(PlatformUtils.debugResetOverrides);

  LegacyProfileCandidate candidate({String? username}) =>
      LegacyProfileCandidate(
        legacyProfileId: 'https://a.example#42',
        profile: const ConnectionProfile(
          id: 'https://a.example#7c9e6679-7425-40de-944b-e07fc1f90ae7',
          origin: 'https://a.example',
          kind: ConnectionKind.selfHosted,
        ),
        username: username,
      );

  Future<Future<bool?>> open(
    WidgetTester tester,
    LegacyProfileCandidate value,
  ) async {
    late Future<bool?> result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                result = confirmLegacyProfileAdoption(context, value);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('names the username and returns true for "mine"', (tester) async {
    final result = await open(tester, candidate(username: 'alex'));

    expect(find.text(l10n.legacyDataTitle), findsOneWidget);
    expect(
      find.text(l10n.legacyDataMessageWithUsername('alex')),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.legacyDataConfirm));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
  });

  testWidgets('uses the generic message after an SSO sign-in', (tester) async {
    final result = await open(tester, candidate());

    expect(find.text(l10n.legacyDataMessage), findsOneWidget);
    await tester.tap(find.text(l10n.legacyDataDecline));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
  });
}
