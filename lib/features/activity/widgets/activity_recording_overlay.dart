import 'dart:async';

import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/features/activity/controllers/activity_recording_controller.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_config.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';
import 'package:endurain/features/activity/repositories/start_countdown_settings_repository.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter_scope.dart';
import 'package:endurain/features/activity/services/recording_live_activity_publisher.dart';
import 'package:endurain/features/activity/services/start_countdown.dart';
import 'package:endurain/features/activity/services/start_countdown_platform_adapter.dart';
import 'package:endurain/features/activity/widgets/activity_recording_controls.dart';
import 'package:endurain/features/activity/widgets/activity_stop_confirmation_dialog.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/features/activity/widgets/start_countdown_dialog.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/widgets.dart';

/// The recording UI that sits on top of the map: the start/pause/stop controls
/// plus the flows behind them (permission prompts, start countdown, stop
/// confirmation, delete and history).
///
/// It is the single entry point the map feature depends on, so the map does not
/// need to know any of these activity pieces. It listens to [controller]
/// itself, which keeps the 1 Hz stats rebuild inside this subtree instead of
/// the whole map.
class ActivityRecordingOverlay extends StatefulWidget {
  const ActivityRecordingOverlay({
    super.key,
    required this.controller,
    required this.startCountdownSettings,
    required this.startCountdownPlatform,
    required this.readAudioAnnouncementSettings,
    required this.historyBuilder,
    this.trailingReservedWidth = 0,
    this.countdownClock,
  });

  final ActivityRecordingController controller;

  /// Width kept free at the trailing edge for the map's floating button.
  final double trailingReservedWidth;

  final StartCountdownSettingsRepository startCountdownSettings;
  final StartCountdownPlatformAdapter startCountdownPlatform;

  /// The current spoken-announcement preferences, read when a recording
  /// starts so a change made in Settings applies to the next one.
  final AudioAnnouncementSettings Function() readAudioAnnouncementSettings;

  /// The activity history page opened from the finished-recording summary.
  final WidgetBuilder historyBuilder;

  /// Clock for the start countdown (tests pass the fake test clock).
  final DateTime Function()? countdownClock;

  @override
  State<ActivityRecordingOverlay> createState() =>
      _ActivityRecordingOverlayState();
}

class _ActivityRecordingOverlayState extends State<ActivityRecordingOverlay> {
  bool _isStopConfirmationOpen = false;

  /// Set for the whole start flow (permission dialogs, countdown, start), from
  /// before its first await, so a second tap cannot start a second flow.
  bool _isStartFlowRunning = false;

  ActivityRecordingController get _activityController => widget.controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolved here rather than at start, so a recording recovered after a
    // restart and a change of language or units reach the Live Activity too.
    final l10n = AppLocalizations.of(context)!;
    _activityController.configureLiveActivity(
      RecordingLiveActivityLabels(
        formatter: context.statsFormatter,
        numberLocale: context.numberFormatLocale,
        activityTypes: {
          for (final type in ActivityType.values)
            type: type.localizedLabel(l10n),
        },
        distance: l10n.activityStatDistance,
        pace: l10n.activityStatPace,
        speed: l10n.activityStatSpeed,
        paused: l10n.activityPausedIndicator,
        autoPaused: l10n.activityAutoPausedIndicator,
      ),
    );
  }

  Future<void> _confirmStopActivity() async {
    final state = _activityController.state;
    if (_isStopConfirmationOpen || (!state.isActive && !state.canRecover)) {
      return;
    }

    _isStopConfirmationOpen = true;
    final action = await showActivityStopConfirmationDialog(context);
    _isStopConfirmationOpen = false;

    if (!mounted) {
      return;
    }

    switch (action) {
      case ActivityStopAction.cancel:
        return;
      case ActivityStopAction.stop:
        await _activityController.stop();
      case ActivityStopAction.discard:
        await _activityController.discard();
    }
  }

  Future<void> _startActivity(ActivityType type) async {
    if (_isStartFlowRunning) {
      return;
    }
    _isStartFlowRunning = true;
    try {
      await _runStartFlow(type);
    } finally {
      _isStartFlowRunning = false;
    }
  }

  Future<void> _runStartFlow(ActivityType type) async {
    final l10n = AppLocalizations.of(context)!;
    final backgroundTrackingReady = await _activityController
        .isBackgroundTrackingReady();
    if (!mounted) {
      return;
    }

    if (!backgroundTrackingReady) {
      final shouldContinue = await DialogUtils.showConfirmDialog(
        context,
        title: l10n.activityBackgroundPermissionTitle,
        message: l10n.activityBackgroundPermissionMessage,
        confirmText: l10n.activityBackgroundPermissionContinue,
      );
      if (!mounted || !shouldContinue) {
        return;
      }

      final permissionReady = await _activityController
          .requestBackgroundTrackingPermission();
      if (!mounted) {
        return;
      }
      if (!permissionReady) {
        final openSettings = await DialogUtils.showConfirmDialog(
          context,
          title: l10n.activityBackgroundPermissionSettingsTitle,
          message: l10n.activityBackgroundPermissionSettingsMessage,
          confirmText: l10n.activityOpenSettings,
        );
        if (mounted && openSettings) {
          await _activityController.openLocationSettings();
        }
        return;
      }
    }

    final announcements = AudioAnnouncementConfig.build(
      l10n: l10n,
      settings: widget.readAudioAnnouncementSettings(),
      activityType: type,
      measurementSystem: context.currentMeasurementSystem,
      languageTag: context.numberFormatLocale,
    );
    final countdown = await widget.startCountdownSettings.getConfig();
    if (!mounted) {
      return;
    }

    final countdownPlatform = widget.startCountdownPlatform;
    // Asked here, with the user looking at the app and just before the first
    // foreground notification, rather than on app launch. The answer never
    // blocks recording.
    await _safely(countdownPlatform.requestNotificationPermission);
    if (!mounted) {
      return;
    }
    var countedDown = false;
    if (countdown.enabled) {
      final outcome = await _runStartCountdown(
        type: type,
        config: countdown,
        announcements: announcements,
        platform: countdownPlatform,
      );
      if (outcome == null) {
        // Skipped: location is not ready, so start right away and let the
        // recording report the problem as usual.
      } else if (outcome == StartCountdownOutcome.cancel || !mounted) {
        await _safely(countdownPlatform.endWarmUp);
        return;
      } else {
        countedDown = true;
      }
    }

    _activityController.configureAudioAnnouncements(announcements);
    try {
      await _activityController.start(type);
    } finally {
      // Ended only after the recorder has started, so the app stays awake
      // (and GPS warm) right up to the first point. On Android the recording
      // has taken over the warm-up's service by now, so this leaves it alone.
      if (countedDown) {
        await _safely(countdownPlatform.endWarmUp);
      }
    }
    if (countedDown &&
        countdown.voiceEnabled &&
        _activityController.state.status == ActivityRecordingStatus.recording) {
      await _safely(
        () => countdownPlatform.speakCue(
          l10n.audioAnnouncementsRecordingStarted,
          duckOtherAudio: announcements.duckOtherAudio,
          languageTag: announcements.languageTag,
        ),
      );
    }
  }

  /// Shows the start countdown. Returns null when it was skipped because
  /// location is not ready, otherwise how it ended.
  Future<StartCountdownOutcome?> _runStartCountdown({
    required ActivityType type,
    required StartCountdownConfig config,
    required AudioAnnouncementConfig announcements,
    required StartCountdownPlatformAdapter platform,
  }) async {
    // Settle any location prompt now, while the phone is still in hand.
    final locationReady = await _activityController.isLocationReady();
    if (!mounted) {
      // The user left the screen: do not start anything.
      return StartCountdownOutcome.cancel;
    }
    if (!locationReady) {
      return null;
    }
    await _safely(() => platform.beginWarmUp(countdownSeconds: config.seconds));
    if (!mounted) {
      return StartCountdownOutcome.cancel;
    }
    return showStartCountdownDialog(
      context,
      seconds: config.seconds,
      activityType: type,
      now: widget.countdownClock,
      onCue: config.voiceEnabled
          ? (secondsLeft) => unawaited(
              _safely(
                () => platform.speakCue(
                  '$secondsLeft',
                  duckOtherAudio: announcements.duckOtherAudio,
                  languageTag: announcements.languageTag,
                ),
              ),
            )
          : null,
    );
  }

  /// Runs a best-effort native countdown call: a missing speech engine or
  /// warm-up must never block starting a recording.
  Future<void> _safely(Future<void> Function() call) async {
    try {
      await call();
    } catch (_) {}
  }

  Future<void> _deleteCompletedActivity() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: l10n.activityDeleteLocalConfirmTitle,
      message: l10n.activityDeleteLocalConfirmMessage,
      confirmText: l10n.activityDeleteLocal,
      isDestructive: true,
    );
    if (!mounted || !confirmed) {
      return;
    }
    await _activityController.discard();
  }

  void _openActivityHistory() {
    unawaited(adaptivePush<void>(context, widget.historyBuilder));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _activityController,
      builder: (context, _) => ActivityRecordingControls(
        state: _activityController.state,
        selectedActivityType: _activityController.selectedActivityType,
        trailingReservedWidth: widget.trailingReservedWidth,
        onActivityTypeChanged: _activityController.selectActivityType,
        onStart: _startActivity,
        onPause: _activityController.pause,
        onResume: _activityController.resume,
        onStop: _confirmStopActivity,
        uploadStatus: _activityController.uploadStatus,
        uploadError: _activityController.uploadError,
        onRetryUpload: _activityController.uploadCompletedGpx,
        onDone: _activityController.clearCompleted,
        onDelete: _deleteCompletedActivity,
        onViewHistory: _openActivityHistory,
        onOpenLocationSettings: _activityController.openLocationSettings,
      ),
    );
  }
}
