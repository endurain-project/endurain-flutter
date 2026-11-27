import 'dart:async';

import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/services/platform/health_connect_settings_service.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/error_localizations.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/layout/readable_content.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the health data Endurain requests and its platform permission state.
///
/// Importing workouts remains in the Health Sync screen. This screen only
/// manages the read access needed for that workflow.
class HealthAccessScreen extends StatefulWidget {
  const HealthAccessScreen({
    super.key,
    this.controller,
    this.createController,
    this.settingsService = const PlatformHealthConnectSettingsService(),
  }) : assert(
         controller != null || createController != null,
         'Pass a controller or a factory for one.',
       );

  /// Injected controller (shared by the caller, or tests); otherwise one is
  /// built with [createController] and owned by the screen.
  final HealthSyncController? controller;
  final HealthSyncController Function()? createController;

  /// Opens the Health Connect permission screen on Android once the system
  /// dialog can no longer be shown. Injected in tests.
  final HealthConnectSettingsService settingsService;

  @override
  State<HealthAccessScreen> createState() => _HealthAccessScreenState();
}

class _HealthAccessScreenState extends State<HealthAccessScreen>
    with OwnedControllers {
  late final HealthSyncController _controller;

  @override
  void initState() {
    super.initState();
    _controller = registerController(
      widget.controller,
      () => widget.createController!(),
    );
    unawaited(_controller.loadStatus());
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
        padding: readableContentPadding(context),
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
    if (!mounted || !_needsHealthConnectGuidance()) return;
    // Health Connect stops showing its dialog after two denials, so point the
    // user at the screen where access can still be allowed.
    final open = await DialogUtils.showConfirmDialog(
      context,
      title: l10n.healthAccessBlockedTitle,
      message: l10n.healthAccessBlockedMessage,
      confirmText: l10n.healthAccessOpenHealthConnect,
    );
    if (open) {
      await widget.settingsService.openPermissions();
    }
  }

  /// Whether, on Android, some requested data is still not allowed after the
  /// permission request.
  bool _needsHealthConnectGuidance() {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    final details = _controller.state.accessDetails;
    return [
      details.workouts,
      details.workoutRoutes,
      details.heartRate,
    ].contains(HealthDataAccessStatus.needsAttention);
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
