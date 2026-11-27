import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/layout/readable_content.dart';
import 'package:material_ui/material_ui.dart';

/// Lets the user pick the unit system used to display distances, speeds,
/// paces, and elevations.
///
/// Mirrors `LanguageSettingsScreen`: the choice is applied immediately through
/// the app-lifetime [MeasurementSystemController], which the root `App`
/// listens to, so every screen re-renders without a restart.
class UnitsSettingsScreen extends StatelessWidget {
  const UnitsSettingsScreen({super.key, required this.controller});

  /// The app-lifetime unit preference this screen edits.
  final MeasurementSystemController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final measurement = controller;
    // The device locale (with region), not the app's resolved language-only
    // locale (the same value as `ActivityStatsFormatterScope.deviceLocale`).
    final deviceDefault = measurement.deviceDefault(
      View.of(context).platformDispatcher.locale,
    );

    return AdaptiveScaffold(
      title: l10n.unitsTitle,
      body: ListenableBuilder(
        listenable: measurement,
        builder: (context, _) {
          final selected = measurement.preference;
          return ListView(
            padding: readableContentPadding(context),
            children: [
              AdaptiveListSection(
                children: [
                  AdaptiveSelectableListTile(
                    title: l10n.unitsSystemDefault,
                    subtitle: _labelFor(deviceDefault, l10n),
                    selected: selected == null,
                    onTap: () => measurement.setPreference(null),
                  ),
                  AdaptiveSelectableListTile(
                    title: l10n.unitsMetric,
                    selected: selected == MeasurementSystem.metric,
                    onTap: () =>
                        measurement.setPreference(MeasurementSystem.metric),
                  ),
                  AdaptiveSelectableListTile(
                    title: l10n.unitsImperial,
                    selected: selected == MeasurementSystem.imperial,
                    onTap: () =>
                        measurement.setPreference(MeasurementSystem.imperial),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _labelFor(MeasurementSystem system, AppLocalizations l10n) {
    return switch (system) {
      MeasurementSystem.metric => l10n.unitsMetric,
      MeasurementSystem.imperial => l10n.unitsImperial,
    };
  }
}
