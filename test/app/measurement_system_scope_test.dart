import 'package:endurain/app/measurement_system_scope.dart';
import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/features/settings/repositories/measurement_settings_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_preferences_store.dart';

void main() {
  const usLocale = Locale('en', 'US');

  MeasurementSystemController newController() => MeasurementSystemController(
    repository: MeasurementSettingsRepository(
      preferences: FakePreferencesStore(),
    ),
  );

  testWidgets('rebuilds only the readers when the preference changes', (
    tester,
  ) async {
    final controller = newController();
    addTearDown(controller.dispose);
    var readerBuilds = 0;
    var bystanderBuilds = 0;
    MeasurementSystem? seen;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MeasurementSystemScope(
          controller: controller,
          child: Column(
            children: [
              Builder(
                builder: (context) {
                  readerBuilds++;
                  seen = MeasurementSystemScope.of(context, usLocale);
                  return const SizedBox();
                },
              ),
              const _Bystander(),
              Builder(
                builder: (context) {
                  bystanderBuilds++;
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
    expect(seen, MeasurementSystem.imperial);
    expect(readerBuilds, 1);
    final bystanderBefore = bystanderBuilds;

    await controller.setPreference(MeasurementSystem.metric);
    await tester.pump();

    expect(seen, MeasurementSystem.metric);
    expect(readerBuilds, 2);
    // A widget that does not read the scope is not rebuilt (the Builder
    // closure above is a const-less sibling, so it rebuilds only when its
    // parent does, which a notifier change does not trigger).
    expect(bystanderBuilds, bystanderBefore);
  });

  testWidgets('falls back to the device region without a scope', (
    tester,
  ) async {
    late MeasurementSystem seen;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seen = MeasurementSystemScope.of(context, const Locale('de', 'DE'));
          return const SizedBox();
        },
      ),
    );

    expect(seen, MeasurementSystem.metric);
  });
}

class _Bystander extends StatelessWidget {
  const _Bystander();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
