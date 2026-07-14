import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/error_localizations.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/material.dart';

/// Shows the health data Endurain requests and its platform permission state.
///
/// Importing workouts remains in the Health Sync screen. This screen only
/// manages the read access needed for that workflow.
class HealthAccessScreen extends StatefulWidget {
  const HealthAccessScreen({super.key, this.controller});

  final HealthSyncController? controller;

  @override
  State<HealthAccessScreen> createState() => _HealthAccessScreenState();
}

class _HealthAccessScreenState extends State<HealthAccessScreen> {
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
          title: l10n.healthAccessScreenTitle,
          body: state.isCheckingStatus
              ? const Center(child: AdaptiveLoadingIndicator())
              : state.error != null &&
                    state.sdkStatus == HealthSdkStatus.unsupported
              ? _StatusErrorBody(
                  error: state.error!,
                  onRetry: _controller.loadStatus,
                )
              : switch (state.sdkStatus) {
                  HealthSdkStatus.unsupported => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        UIConstants.paddingStandard,
                      ),
                      child: Text(
                        l10n.healthSyncUnsupported,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  HealthSdkStatus.needsProviderInstall => _InstallProviderBody(
                    onInstall: _controller.installHealthConnect,
                  ),
                  HealthSdkStatus.available => _buildAvailableBody(l10n),
                },
        );
      },
    );
  }

  Widget _buildAvailableBody(AppLocalizations l10n) {
    final details = _controller.state.accessDetails;
    return RefreshIndicator.adaptive(
      onRefresh: _controller.loadStatus,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(UIConstants.paddingStandard),
        children: [
          AdaptiveListSection(
            header: l10n.healthAccessRequestedData,
            children: [
              _dataTile(l10n.healthAccessWorkouts, details.workouts, l10n),
              _dataTile(
                l10n.healthAccessWorkoutRoutes,
                details.workoutRoutes,
                l10n,
              ),
              _dataTile(l10n.healthAccessHeartRate, details.heartRate, l10n),
            ],
          ),
          if (!details.canInspectIndividualPermissions)
            Padding(
              padding: const EdgeInsets.only(top: UIConstants.paddingStandard),
              child: Text(
                l10n.healthAccessSystemManagedNotice,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: UIConstants.paddingLarge),
          AdaptiveButton(
            label: details.canInspectIndividualPermissions
                ? l10n.healthAccessReview
                : l10n.healthAccessReviewIos,
            onPressed: () => _reviewAccess(details, l10n),
          ),
          const SizedBox(height: UIConstants.paddingSmall),
          AdaptiveButton(
            label: l10n.healthAccessDisconnect,
            onPressed: () => _disconnect(l10n),
            destructive: true,
          ),
          if (_controller.state.error case final error?) ...[
            const SizedBox(height: UIConstants.paddingSmall),
            Text(
              localizedErrorMessage(error, l10n),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _disconnect(AppLocalizations l10n) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: l10n.healthAccessDisconnectTitle,
      message: l10n.healthAccessDisconnectMessage,
      confirmText: l10n.healthAccessDisconnect,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await _controller.disconnect();
  }

  Future<void> _reviewAccess(
    HealthDataAccessDetails details,
    AppLocalizations l10n,
  ) async {
    if (!details.canInspectIndividualPermissions) {
      await DialogUtils.showMessage(
        context,
        l10n.healthAccessReviewIosInstructions,
      );
      return;
    }
    await _controller.requestAccess();
  }

  AdaptiveListTile _dataTile(
    String title,
    HealthDataAccessStatus status,
    AppLocalizations l10n,
  ) {
    final canInspect =
        _controller.state.accessDetails.canInspectIndividualPermissions;
    return AdaptiveListTile(
      title: title,
      subtitle: canInspect
          ? switch (status) {
              HealthDataAccessStatus.allowed => l10n.healthAccessAllowed,
              HealthDataAccessStatus.needsAttention =>
                l10n.healthAccessNeedsAttention,
            }
          : l10n.healthAccessManagedBySystem,
    );
  }
}

class _StatusErrorBody extends StatelessWidget {
  const _StatusErrorBody({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _InstallProviderBody extends StatelessWidget {
  const _InstallProviderBody({required this.onInstall});

  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingStandard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monitor_heart_outlined, size: 48),
            const SizedBox(height: UIConstants.paddingStandard),
            Text(
              l10n.healthSyncInstallProviderDescription,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.paddingStandard),
            AdaptiveButton(
              label: l10n.healthSyncInstallProvider,
              onPressed: onInstall,
            ),
          ],
        ),
      ),
    );
  }
}
