import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/utils/date_time_formatting.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/features/activity/screens/activity_details_screen.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:endurain/features/health/models/health_imported_workout.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_sync_state.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/core/utils/error_localizations.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key, this.controller});

  /// Optional injected controller — if omitted, resolved from [AppScope].
  final HealthSyncController? controller;

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  late final HealthSyncController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        AppScope.servicesOf(
          context,
          listen: false,
        ).createHealthSyncController();
    _controller.loadStatus();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return AdaptiveScaffold(
          title: l10n.healthSyncScreenTitle,
          body: _buildBody(context, l10n, state),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    HealthSyncState state,
  ) {
    if (state.isCheckingStatus) {
      return const Center(child: AdaptiveLoadingIndicator());
    }
    if (state.error != null && state.sdkStatus == HealthSdkStatus.unsupported) {
      return _buildStatusError(context, l10n, state.error!);
    }
    return switch (state.sdkStatus) {
      HealthSdkStatus.unsupported => _buildUnsupportedBody(l10n),
      HealthSdkStatus.needsProviderInstall => _buildInstallBody(context, l10n),
      HealthSdkStatus.available => _buildAvailableBody(context, l10n, state),
    };
  }

  Widget _buildStatusError(
    BuildContext context,
    AppLocalizations l10n,
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingStandard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizedErrorMessage(error, l10n),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.paddingStandard),
            AdaptiveButton(
              label: l10n.activityHistoryRefresh,
              onPressed: _controller.loadStatus,
              icon: const AdaptiveIcon(
                materialIcon: Icons.refresh,
                cupertinoIcon: CupertinoIcons.refresh,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SDK unavailable ───────────────────────────────────────────────────────

  Widget _buildUnsupportedBody(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingStandard),
        child: Text(l10n.healthSyncUnsupported, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildInstallBody(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingStandard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AdaptiveIcon(
              materialIcon: Icons.monitor_heart_outlined,
              cupertinoIcon: CupertinoIcons.heart,
              size: 48,
            ),
            const SizedBox(height: UIConstants.paddingStandard),
            Text(
              l10n.healthSyncInstallProviderDescription,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.paddingStandard),
            AdaptiveButton(
              label: l10n.healthSyncInstallProvider,
              onPressed: () => _controller.installHealthConnect(),
            ),
          ],
        ),
      ),
    );
  }

  // ── SDK available ─────────────────────────────────────────────────────────

  Widget _buildAvailableBody(
    BuildContext context,
    AppLocalizations l10n,
    HealthSyncState state,
  ) {
    if (state.authStatus != HealthAuthorizationStatus.granted) {
      return _buildAuthorizationBody(context, l10n, state);
    }
    return _buildWorkoutListBody(context, l10n, state);
  }

  Widget _buildAuthorizationBody(
    BuildContext context,
    AppLocalizations l10n,
    HealthSyncState state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingStandard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AdaptiveIcon(
              materialIcon: Icons.monitor_heart_outlined,
              cupertinoIcon: CupertinoIcons.heart,
              size: 48,
            ),
            const SizedBox(height: UIConstants.paddingStandard),
            AdaptiveButton(
              label: l10n.healthSyncAuthorize,
              onPressed: () => _controller.requestAccess(),
            ),
            if (state.error != null) ...[
              const SizedBox(height: UIConstants.paddingSmall),
              Text(
                localizedErrorMessage(state.error!, l10n),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutListBody(
    BuildContext context,
    AppLocalizations l10n,
    HealthSyncState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(UIConstants.paddingStandard),
          child: AdaptiveSegmentedControl<HealthSyncView>(
            labels: {
              HealthSyncView.available: l10n.healthSyncViewAvailable,
              HealthSyncView.imported: l10n.healthSyncViewImported,
            },
            selected: state.selectedView,
            onChanged: _controller.selectView,
          ),
        ),
        if (state.isLoadingWorkouts ||
            state.isImporting ||
            state.isLoadingImported)
          const AdaptiveProgressBar(),
        Expanded(
          child: state.selectedView == HealthSyncView.available
              ? _AvailableWorkoutsView(controller: _controller, state: state)
              : _ImportedWorkoutsView(controller: _controller, state: state),
        ),
      ],
    );
  }
}

// ── Content views ────────────────────────────────────────────────────────────

/// Inline, centered error message shown within a workout list surface.
class _InlineError extends StatelessWidget {
  const _InlineError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: UIConstants.paddingStandard),
      child: Text(
        localizedErrorMessage(error, l10n),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// The "Available" tab: import range, auto-sync toggle, notices, and the list
/// of health-platform workouts eligible for import.
class _AvailableWorkoutsView extends StatelessWidget {
  const _AvailableWorkoutsView({required this.controller, required this.state});

  final HealthSyncController controller;
  final HealthSyncState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final automationSubtitle = [
      l10n.healthSyncAutoSyncSubtitle,
      if (state.lastSyncAt != null)
        l10n.healthSyncImportedAt(
          formatLocalDateTime(context, state.lastSyncAt!),
        ),
    ].join('\n');
    return RefreshIndicator.adaptive(
      onRefresh: controller.loadImportableWorkouts,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(UIConstants.paddingStandard),
        children: [
          AdaptiveListSection(
            children: [_buildRangeSelector(context, l10n, state)],
          ),
          const SizedBox(height: UIConstants.paddingStandard),
          AdaptiveListSection(
            children: [
              AdaptiveSwitchListTile(
                title: l10n.healthSyncAutoSyncTitle,
                subtitle: automationSubtitle,
                value: state.autoSyncOnResume,
                onChanged: state.isImporting || state.isUpdatingAutoSync
                    ? null
                    : controller.setAutoSyncOnResume,
              ),
            ],
          ),
          if (state.importedCount > 0) ...[
            const SizedBox(height: UIConstants.paddingStandard),
            Text(
              l10n.healthSyncImportedCount(state.importedCount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (state.routeConsentDeniedCount > 0)
            _buildRouteConsentNotice(context, l10n),
          if (_showNoRoutesExplanation(state))
            _buildNoRoutesNotice(context, l10n),
          if (state.error != null) _InlineError(error: state.error!),
          _buildToolbar(context, l10n, state),
          _buildWorkoutList(context, l10n, state),
          if (state.availableHasMore) ...[
            const SizedBox(height: UIConstants.paddingStandard),
            Center(
              child: AdaptiveButton(
                label: l10n.activityHistoryLoadMore,
                variant: AdaptiveButtonVariant.secondary,
                onPressed: state.isLoadingMoreAvailable
                    ? null
                    : controller.loadMoreAvailable,
              ),
            ),
          ],
          _buildImportActions(context, l10n, state),
        ],
      ),
    );
  }

  Widget _buildRangeSelector(
    BuildContext context,
    AppLocalizations l10n,
    HealthSyncState state,
  ) {
    return AdaptiveListTile(
      title: l10n.healthSyncDateRange,
      subtitle: _rangeLabel(context, l10n, state.selectedRange),
      leading: const AdaptiveIcon(
        materialIcon: Icons.date_range,
        cupertinoIcon: CupertinoIcons.calendar,
      ),
      onTap: () => _selectRange(context, l10n, state.selectedRange),
    );
  }

  Future<void> _selectRange(
    BuildContext context,
    AppLocalizations l10n,
    HealthImportRange current,
  ) async {
    final labels = <HealthImportRangePreset, String>{
      HealthImportRangePreset.last30Days: l10n.healthSyncRange30Days,
      HealthImportRangePreset.last3Months: l10n.healthSyncRange3Months,
      HealthImportRangePreset.last6Months: l10n.healthSyncRange6Months,
      HealthImportRangePreset.lastYear: l10n.healthSyncRangeYear,
      HealthImportRangePreset.allHistory: l10n.healthSyncRangeAll,
      HealthImportRangePreset.custom: l10n.healthSyncRangeCustom,
    };
    final preset = PlatformUtils.isApplePlatform
        ? await showCupertinoModalPopup<HealthImportRangePreset>(
            context: context,
            builder: (context) => CupertinoActionSheet(
              title: Text(l10n.healthSyncDateRange),
              actions: [
                for (final entry in labels.entries)
                  CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(context, entry.key),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (entry.key == current.preset) ...[
                          const Icon(CupertinoIcons.check_mark, size: 18),
                          const SizedBox(width: UIConstants.paddingCompact),
                        ],
                        Text(entry.value),
                      ],
                    ),
                  ),
              ],
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ),
          )
        : await showDialog<HealthImportRangePreset>(
            context: context,
            builder: (context) => SimpleDialog(
              title: Text(l10n.healthSyncDateRange),
              children: [
                for (final entry in labels.entries)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, entry.key),
                    child: Text(entry.value),
                  ),
              ],
            ),
          );
    if (!context.mounted || preset == null) return;
    if (preset != HealthImportRangePreset.custom) {
      await controller.setRange(_rangeForPreset(preset));
      return;
    }

    final now = DateTime.now();
    final custom = current.preset == HealthImportRangePreset.custom;
    final selected = await showAdaptiveDateRangePicker(
      context: context,
      initialStart: custom
          ? current.customStartDate!
          : now.subtract(const Duration(days: 30)),
      initialEnd: custom ? current.customEndDate! : now,
      firstDate: DateTime(1970),
      lastDate: now,
      startLabel: l10n.activityHistoryStartedAt,
      endLabel: l10n.activityHistoryEndedAt,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.ok,
    );
    if (selected == null) return;
    await controller.setRange(
      HealthImportRange.custom(
        startDate: selected.start,
        endDate: selected.end,
      ),
    );
  }

  HealthImportRange _rangeForPreset(HealthImportRangePreset preset) {
    return switch (preset) {
      HealthImportRangePreset.last30Days =>
        const HealthImportRange.last30Days(),
      HealthImportRangePreset.last3Months =>
        const HealthImportRange.last3Months(),
      HealthImportRangePreset.last6Months =>
        const HealthImportRange.last6Months(),
      HealthImportRangePreset.lastYear => const HealthImportRange.lastYear(),
      HealthImportRangePreset.allHistory =>
        const HealthImportRange.allHistory(),
      HealthImportRangePreset.custom => throw StateError('Custom needs dates.'),
    };
  }

  String _rangeLabel(
    BuildContext context,
    AppLocalizations l10n,
    HealthImportRange range,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return switch (range.preset) {
      HealthImportRangePreset.last30Days => l10n.healthSyncRange30Days,
      HealthImportRangePreset.last3Months => l10n.healthSyncRange3Months,
      HealthImportRangePreset.last6Months => l10n.healthSyncRange6Months,
      HealthImportRangePreset.lastYear => l10n.healthSyncRangeYear,
      HealthImportRangePreset.allHistory => l10n.healthSyncRangeAll,
      HealthImportRangePreset.custom =>
        '${DateFormat.yMd(locale).format(range.customStartDate!)} - '
            '${DateFormat.yMd(locale).format(range.customEndDate!)}',
    };
  }

  Widget _buildRouteConsentNotice(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.paddingStandard,
        vertical: UIConstants.paddingSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _routeConsentGuidance(l10n),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
          if (defaultTargetPlatform == TargetPlatform.iOS)
            AdaptiveButton(
              label: l10n.healthSyncReviewAccess,
              variant: AdaptiveButtonVariant.secondary,
              onPressed: () => DialogUtils.showMessage(
                context,
                l10n.healthAccessReviewIosInstructions,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoRoutesNotice(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.paddingStandard,
        vertical: UIConstants.paddingSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdaptiveIcon(
            materialIcon: Icons.info_outline,
            cupertinoIcon: CupertinoIcons.info_circle,
            size: 18,
          ),
          const SizedBox(width: UIConstants.paddingSmall),
          Expanded(
            child: Text(
              l10n.healthSyncNoRoutesExplanation,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows guidance when workouts were found but none carry a GPS route (e.g.
  /// activities written to the health platform by apps like Garmin Connect
  /// that don't share routes). Suppressed while loading and when the absence is
  /// already explained by the route-consent guidance.
  bool _showNoRoutesExplanation(HealthSyncState state) {
    return !state.isLoadingWorkouts &&
        state.routeConsentDeniedCount == 0 &&
        state.importableWorkouts.isNotEmpty &&
        !state.importableWorkouts.any((w) => w.hasRoute);
  }

  String _routeConsentGuidance(AppLocalizations l10n) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => l10n.healthSyncRouteConsentGuidanceIos,
      _ => l10n.healthSyncRouteConsentGuidance,
    };
  }

  Widget _buildToolbar(
    BuildContext context,
    AppLocalizations l10n,
    HealthSyncState state,
  ) {
    final hasImportable = state.importableWorkouts.any((w) => w.hasRoute);
    if (!hasImportable) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: UIConstants.paddingStandard,
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: UIConstants.paddingCompact,
        runSpacing: UIConstants.paddingSmall,
        children: [
          AdaptiveButton(
            label: l10n.healthSyncSelectAll,
            variant: AdaptiveButtonVariant.secondary,
            onPressed: state.isImporting ? null : controller.selectAll,
          ),
          AdaptiveButton(
            label: l10n.healthSyncClearSelection,
            variant: AdaptiveButtonVariant.secondary,
            onPressed: state.selectedSourceIds.isEmpty || state.isImporting
                ? null
                : controller.clearSelection,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutList(
    BuildContext context,
    AppLocalizations l10n,
    HealthSyncState state,
  ) {
    if (state.importableWorkouts.isEmpty) {
      return _buildEmptyList(l10n, state);
    }
    return AdaptiveListSection(
      children: [
        for (final workout in state.importableWorkouts)
          _WorkoutRow(
            workout: workout,
            title: _formatTitle(context, l10n, workout),
            subtitle: _formatSubtitle(context, workout),
            isSelected: state.selectedSourceIds.contains(workout.sourceId),
            noRouteLabel: l10n.healthSyncNoRouteLabel,
            onChanged: workout.hasRoute && !state.isImporting
                ? (_) => controller.toggleSelection(workout.sourceId)
                : null,
          ),
      ],
    );
  }

  /// Empty message within the parent scrollable refresh surface.
  Widget _buildEmptyList(AppLocalizations l10n, HealthSyncState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingXLarge),
      child: Text(
        state.isLoadingWorkouts ? '' : l10n.healthSyncEmptyState,
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTitle(
    BuildContext context,
    AppLocalizations l10n,
    HealthWorkout workout,
  ) {
    final typeLabel = workout.type.toActivityType().localizedLabel(l10n);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateStr = DateFormat.yMd(locale).format(workout.startedAt.toLocal());
    return '$typeLabel · $dateStr';
  }

  String? _formatSubtitle(BuildContext context, HealthWorkout workout) {
    const formatter = ActivityStatsFormatter();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final parts = <String>[
      formatter.formatDuration(
        workout.endedAt.difference(workout.startedAt).inSeconds,
      ),
    ];
    if (workout.distanceMeters != null) {
      parts.add(
        formatter.formatDistance(workout.distanceMeters!, locale: locale),
      );
    }
    return parts.join(' · ');
  }

  Widget _buildImportActions(
    BuildContext context,
    AppLocalizations l10n,
    HealthSyncState state,
  ) {
    final selectedCount = state.selectedSourceIds.length;
    final canImport = selectedCount > 0 && !state.isImporting;
    return Padding(
      padding: const EdgeInsets.only(top: UIConstants.paddingStandard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveButton(
            label: l10n.healthSyncImportSelected(selectedCount),
            onPressed: canImport ? () => controller.importSelected() : null,
            expand: true,
          ),
        ],
      ),
    );
  }
}

/// The "Imported" tab: previously imported workouts and their upload status.
class _ImportedWorkoutsView extends StatelessWidget {
  const _ImportedWorkoutsView({required this.controller, required this.state});

  final HealthSyncController controller;
  final HealthSyncState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator.adaptive(
      onRefresh: controller.loadImported,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(UIConstants.paddingStandard),
        children: [
          if (state.error != null) ...[
            _InlineError(error: state.error!),
            Center(
              child: AdaptiveButton(
                label: l10n.activityHistoryRefresh,
                variant: AdaptiveButtonVariant.secondary,
                onPressed: state.isLoadingImported
                    ? null
                    : controller.loadImported,
              ),
            ),
            const SizedBox(height: UIConstants.paddingStandard),
          ],
          if (state.importedWorkouts.isEmpty && !state.isLoadingImported)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: UIConstants.paddingXLarge,
              ),
              child: Text(
                l10n.healthSyncImportedEmpty,
                textAlign: TextAlign.center,
              ),
            )
          else if (state.importedWorkouts.isNotEmpty)
            AdaptiveListSection(
              children: [
                for (final imported in state.importedWorkouts)
                  _ImportedWorkoutTile(
                    imported: imported,
                    onTap: imported.localActivity == null
                        ? null
                        : () => adaptivePush<void>(
                            context,
                            (_) => ActivityDetailsScreen(
                              recordId: imported.localActivityId,
                            ),
                          ),
                    onRestore: imported.localActivity == null
                        ? () => controller.restoreMissingImport(imported)
                        : null,
                  ),
              ],
            ),
          if (state.importedHasMore) ...[
            const SizedBox(height: UIConstants.paddingStandard),
            Center(
              child: AdaptiveButton(
                label: l10n.activityHistoryLoadMore,
                variant: AdaptiveButtonVariant.secondary,
                onPressed: state.isLoadingImported
                    ? null
                    : () => controller.loadImported(reset: false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Workout row ───────────────────────────────────────────────────────────────

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({
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
                  label: AppLocalizations.of(
                    context,
                  )!.healthSyncBadgeNonImportable,
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
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: foreground, letterSpacing: 0),
      ),
    );
  }
}

class _ImportedWorkoutTile extends StatelessWidget {
  const _ImportedWorkoutTile({
    required this.imported,
    this.onTap,
    this.onRestore,
  });

  final HealthImportedWorkout imported;
  final VoidCallback? onTap;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activity = imported.localActivity;
    final title = activity == null
        ? l10n.activityHistoryGpxMissing
        : l10n.activityHistoryEntryTitle(
            activity.activityType.localizedLabel(l10n),
            DateFormat.yMd(
              Localizations.localeOf(context).toLanguageTag(),
            ).format(activity.endedAt.toLocal()),
          );
    final subtitle = [
      l10n.healthSyncImportedAt(
        formatLocalDateTime(context, imported.importedAt),
      ),
      if (activity != null)
        l10n.activityHistoryUploadStatus(
          _uploadStatusLabel(l10n, activity.uploadStatus),
        )
      else
        l10n.activityHistoryGpxMissing,
    ].join('\n');
    return AdaptiveListTile(
      title: title,
      subtitle: subtitle,
      leading: AdaptiveIcon(
        materialIcon: activity == null
            ? Icons.restore
            : _uploadStatusIcon(activity.uploadStatus),
        cupertinoIcon: activity == null
            ? CupertinoIcons.arrow_counterclockwise
            : _uploadStatusCupertinoIcon(activity.uploadStatus),
      ),
      trailing: onRestore == null
          ? null
          : AdaptiveButton(
              label: l10n.healthSyncRestore,
              variant: AdaptiveButtonVariant.secondary,
              onPressed: onRestore,
            ),
      onTap: onTap,
    );
  }

  IconData _uploadStatusIcon(LocalActivityUploadStatus status) {
    return switch (status) {
      LocalActivityUploadStatus.pending => Icons.cloud_upload_outlined,
      LocalActivityUploadStatus.uploaded => Icons.cloud_done,
      LocalActivityUploadStatus.failed => Icons.cloud_off,
    };
  }

  IconData _uploadStatusCupertinoIcon(LocalActivityUploadStatus status) {
    return switch (status) {
      LocalActivityUploadStatus.pending => CupertinoIcons.cloud_upload,
      LocalActivityUploadStatus.uploaded => CupertinoIcons.cloud_upload_fill,
      LocalActivityUploadStatus.failed =>
        CupertinoIcons.exclamationmark_triangle,
    };
  }
}

String _uploadStatusLabel(
  AppLocalizations l10n,
  LocalActivityUploadStatus status,
) {
  return switch (status) {
    LocalActivityUploadStatus.pending => l10n.activityUploadStatusPending,
    LocalActivityUploadStatus.uploaded => l10n.activityUploadStatusUploaded,
    LocalActivityUploadStatus.failed => l10n.activityUploadStatusFailed,
  };
}
