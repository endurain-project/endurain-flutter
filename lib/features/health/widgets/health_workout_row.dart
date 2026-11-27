import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:material_ui/material_ui.dart';

/// One health-platform workout in the "Available" list, with its selection
/// checkbox (disabled when the workout has no route).
class HealthWorkoutRow extends StatelessWidget {
  const HealthWorkoutRow({
    super.key,
    required this.workout,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.noRouteLabel,
    this.onChanged,
  });

  final HealthWorkout workout;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final String noRouteLabel;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveCheckboxListTile(
      value: workout.hasRoute ? isSelected : false,
      onChanged: onChanged,
      showControl: workout.hasRoute,
      secondary: _workoutIcon(workout.type),
      title: workout.hasRoute
          ? Text(title)
          : Wrap(
              spacing: UIConstants.paddingCompact,
              runSpacing: UIConstants.paddingSmall,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(title),
                _NonImportableBadge(
                  label: AppLocalizations.of(context)!
                      .healthSyncBadgeNonImportable,
                ),
              ],
            ),
      subtitle: workout.hasRoute
          ? (subtitle == null ? null : Text(subtitle!))
          : Text(
              noRouteLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }

  Widget _workoutIcon(HealthWorkoutType type) {
    final icon = switch (type) {
      HealthWorkoutType.run => Icons.directions_run,
      HealthWorkoutType.ride => Icons.directions_bike,
      HealthWorkoutType.walk => Icons.directions_walk,
      HealthWorkoutType.hike => Icons.hiking,
      HealthWorkoutType.other => Icons.fitness_center,
    };
    return Icon(icon);
  }
}

class _NonImportableBadge extends StatelessWidget {
  const _NonImportableBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground, letterSpacing: 0),
      ),
    );
  }
}
