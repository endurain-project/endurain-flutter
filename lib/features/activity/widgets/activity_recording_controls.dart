import 'dart:math' as math;

import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_upload_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/widgets/activity_stats_display.dart';
import 'package:endurain/features/activity/widgets/activity_type_picker.dart';
import 'package:endurain/features/activity/widgets/activity_upload_status_panel.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ActivityRecordingControls extends StatelessWidget {
  static const double _idleControlHeight = 56;

  const ActivityRecordingControls({
    super.key,
    required this.state,
    required this.selectedActivityType,
    required this.onActivityTypeChanged,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    this.uploadStatus = ActivityUploadStatus.idle,
    this.uploadError,
    this.onRetryUpload,
    this.onDone,
    this.onDelete,
    this.onViewHistory,
    this.onOpenLocationSettings,
    this.trailingReservedWidth = 0,
  });

  final ActivityRecordingState state;
  final ActivityType selectedActivityType;
  final ValueChanged<ActivityType>? onActivityTypeChanged;
  final ValueChanged<ActivityType>? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final ActivityUploadStatus uploadStatus;
  final AppException? uploadError;
  final VoidCallback? onRetryUpload;
  final VoidCallback? onDone;
  final VoidCallback? onDelete;
  final VoidCallback? onViewHistory;
  final VoidCallback? onOpenLocationSettings;
  final double trailingReservedWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controls = _buildControls(l10n);
    final errorMessage = _recordingErrorMessage(l10n);
    final isApplePlatform = PlatformUtils.isApplePlatform;
    final overlayColor = isApplePlatform
        ? CupertinoDynamicColor.resolve(
            CupertinoTheme.of(context).barBackgroundColor,
            context,
          )
        : Theme.of(context).colorScheme.surface;

    final overlay = LayoutBuilder(
      builder: (context, constraints) {
        final reserveTrailingSpace =
            trailingReservedWidth > 0 && constraints.maxWidth < 480;
        final availableWidth = reserveTrailingSpace
            ? math.max(0.0, constraints.maxWidth - trailingReservedWidth)
            : constraints.maxWidth;
        final maxWidth = math.min(360.0, availableWidth);
        final maxHeight = math.min(
          360.0,
          math.max(120.0, constraints.maxHeight),
        );

        return Align(
          alignment: reserveTrailingSpace
              ? Alignment.bottomLeft
              : Alignment.bottomCenter,
          child: ConstrainedBox(
            key: const ValueKey('activityRecordingControlsSurface'),
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: overlayColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 12,
                    color: Color(0x33000000),
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (errorMessage != null) ...[
                        Text(
                          errorMessage,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        if (state.lastError ==
                                ActivityRecordingError
                                    .locationPermissionDeniedForever ||
                            state.lastError ==
                                ActivityRecordingError
                                    .backgroundPermissionRequired) ...[
                          const SizedBox(height: 8),
                          AdaptiveButton(
                            label: l10n.activityOpenSettings,
                            onPressed: onOpenLocationSettings,
                            variant: AdaptiveButtonVariant.secondary,
                            icon: const AdaptiveIcon(
                              materialIcon: Icons.settings,
                              cupertinoIcon: CupertinoIcons.settings,
                              size: 20,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                      ActivityStatsDisplay(state: state),
                      if (state.isActive ||
                          state.status == ActivityRecordingStatus.stopping ||
                          state.status == ActivityRecordingStatus.completed)
                        const SizedBox(height: 8),
                      if (state.status ==
                          ActivityRecordingStatus.completed) ...[
                        ActivityUploadStatusPanel(
                          status: uploadStatus,
                          error: uploadError,
                          onRetry: onRetryUpload,
                          onDone: onDone,
                          onDelete: onDelete,
                          onViewHistory: onViewHistory,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: controls,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // The floating location button is positioned as SafeArea inset +
    // buttonOuterPadding on every platform (see AdaptiveScaffold). Mirror that
    // exact model here so the overlay's bottom edge lines up with the floating
    // control on devices with a home indicator or gesture inset. SafeArea
    // consumes the inset and the matching padding is added on top, instead of
    // SafeArea.minimum which would apply max(inset, padding) and drift apart
    // once the inset exceeds the padding.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(
          LocationMarkerConstants.buttonOuterPadding,
        ),
        child: overlay,
      ),
    );
  }

  List<Widget> _buildControls(AppLocalizations l10n) {
    switch (state.status) {
      case ActivityRecordingStatus.recording:
        return [
          _controlButton(
            label: l10n.activityPause,
            materialIcon: Icons.pause,
            cupertinoIcon: CupertinoIcons.pause_fill,
            onPressed: onPause,
            variant: AdaptiveButtonVariant.secondary,
          ),
          _controlButton(
            label: l10n.activityStop,
            materialIcon: Icons.stop,
            cupertinoIcon: CupertinoIcons.stop_fill,
            onPressed: onStop,
            destructive: true,
          ),
        ];
      case ActivityRecordingStatus.paused:
        return [
          _controlButton(
            label: l10n.activityResume,
            materialIcon: Icons.play_arrow,
            cupertinoIcon: CupertinoIcons.play_arrow,
            onPressed: onResume,
          ),
          _controlButton(
            label: l10n.activityStop,
            materialIcon: Icons.stop,
            cupertinoIcon: CupertinoIcons.stop_fill,
            onPressed: onStop,
            destructive: true,
          ),
        ];
      case ActivityRecordingStatus.stopping:
        return [
          _controlButton(
            label: l10n.activityStopping,
            materialIcon: Icons.stop,
            cupertinoIcon: CupertinoIcons.stop_fill,
            onPressed: null,
            destructive: true,
          ),
        ];
      case ActivityRecordingStatus.idle:
      case ActivityRecordingStatus.failed:
        return [
          _IdleStartControls(
            selectedActivityType: selectedActivityType,
            onActivityTypeChanged: onActivityTypeChanged,
            onStart: onStart == null
                ? null
                : () => onStart!(selectedActivityType),
            l10n: l10n,
          ),
        ];
      case ActivityRecordingStatus.completed:
        return [];
    }
  }

  String? _recordingErrorMessage(AppLocalizations l10n) {
    if (state.status != ActivityRecordingStatus.failed) {
      return null;
    }
    return state.lastError?.localizedMessage(l10n) ??
        l10n.activityRecordingFailed;
  }

  Widget _controlButton({
    required String label,
    required IconData materialIcon,
    required IconData cupertinoIcon,
    required VoidCallback? onPressed,
    AdaptiveButtonVariant variant = AdaptiveButtonVariant.primary,
    bool destructive = false,
  }) {
    return Tooltip(
      message: label,
      child: AdaptiveButton(
        label: label,
        onPressed: onPressed,
        variant: variant,
        destructive: destructive,
        icon: AdaptiveIcon(
          materialIcon: materialIcon,
          cupertinoIcon: cupertinoIcon,
          size: 20,
        ),
      ),
    );
  }
}

class _IdleStartControls extends StatelessWidget {
  const _IdleStartControls({
    required this.selectedActivityType,
    required this.onActivityTypeChanged,
    required this.onStart,
    required this.l10n,
  });

  final ActivityType selectedActivityType;
  final ValueChanged<ActivityType>? onActivityTypeChanged;
  final VoidCallback? onStart;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: ActivityRecordingControls._idleControlHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ActivityTypePicker(
                    selectedType: selectedActivityType,
                    onChanged: onActivityTypeChanged,
                  ),
                ),
                const SizedBox(width: 8),
                _StartActivityIconButton(
                  onPressed: onStart,
                  label: l10n.activityStart,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartActivityIconButton extends StatelessWidget {
  const _StartActivityIconButton({
    required this.onPressed,
    required this.label,
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final button = PlatformUtils.isApplePlatform
        ? CupertinoButton(
            key: const ValueKey('activityStartButton'),
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(8),
            color: CupertinoTheme.of(context).primaryColor,
            disabledColor: CupertinoColors.quaternarySystemFill,
            onPressed: onPressed,
            child: Icon(
              CupertinoIcons.play_arrow,
              color: onPressed == null
                  ? CupertinoColors.inactiveGray
                  : CupertinoColors.white,
              size: 26,
            ),
          )
        : FilledButton(
            key: const ValueKey('activityStartButton'),
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              fixedSize: const Size.square(
                ActivityRecordingControls._idleControlHeight,
              ),
              minimumSize: const Size.square(
                ActivityRecordingControls._idleControlHeight,
              ),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Icon(
              Icons.play_arrow,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 28,
            ),
          );

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: SizedBox.square(
          dimension: ActivityRecordingControls._idleControlHeight,
          child: button,
        ),
      ),
    );
  }
}
