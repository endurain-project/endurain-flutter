import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/utils/error_localizations.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_sync_state.dart';
import 'package:endurain/features/health/widgets/health_sync_available_view.dart';
import 'package:endurain/features/health/widgets/health_sync_imported_view.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key, this.controller});

  /// Optional injected controller — if omitted, resolved from [AppScope].
  final HealthSyncController? controller;

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen>
    with OwnedControllers {
  late final HealthSyncController _controller;

  @override
  void initState() {
    super.initState();
    _controller = registerController(
      widget.controller,
      () => AppScope.servicesOf(
        context,
        listen: false,
      ).createHealthSyncController(),
    );
    _controller.loadStatus();
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
              ? HealthSyncAvailableView(controller: _controller, state: state)
              : HealthSyncImportedView(controller: _controller, state: state),
        ),
      ],
    );
  }
}
