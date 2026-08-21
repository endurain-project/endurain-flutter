import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter_scope.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:material_ui/material_ui.dart';

/// Lets the user pick the unit system used to display distances, speeds,
/// paces, and elevations.
///
/// Mirrors `LanguageSettingsScreen`: the choice is applied immediately through
/// the app-lifetime [MeasurementSystemController], which the root `App`
/// listens to, so every screen re-renders without a restart.
class UnitsSettingsScreen extends StatelessWidget {
  const UnitsSettingsScreen({super.key, this.controller});

  /// Optional override for tests; otherwise resolved from [AppScope].
  final MeasurementSystemController? controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final measurement =
        controller ??
        AppScope.servicesOf(context, listen: false).measurementSystemController;
    // The device locale (with region), not the app's resolved language-only
    // locale — see `ActivityStatsFormatterScope.deviceLocale`.
    final deviceDefault = measurement.deviceDefault(context.deviceLocale);

    return AdaptiveScaffold(
      title: l10n.unitsTitle,
      body: ListenableBuilder(
        listenable: measurement,
        builder: (context, _) {
          final selected = measurement.preference;
          return ListView(
            padding: const EdgeInsets.all(UIConstants.paddingStandard),
            children: [
              AdaptiveListSection(
                children: [
                  _UnitsOptionTile(
                    title: l10n.unitsSystemDefault,
                    subtitle: _labelFor(deviceDefault, l10n),
                    isSelected: selected == null,
                    onTap: () => measurement.setPreference(null),
                  ),
                  _UnitsOptionTile(
                    title: l10n.unitsMetric,
                    isSelected: selected == MeasurementSystem.metric,
                    onTap: () =>
                        measurement.setPreference(MeasurementSystem.metric),
                  ),
                  _UnitsOptionTile(
                    title: l10n.unitsImperial,
                    isSelected: selected == MeasurementSystem.imperial,
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

class _UnitsOptionTile extends StatelessWidget {
  const _UnitsOptionTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdaptiveListTile(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
    );
  }
}
