import 'dart:async';

import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_recording_stats.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/recording_live_activity_content.dart';
import 'package:endurain/features/activity/services/activity_stats_calculator.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter.dart';
import 'package:endurain/features/activity/services/recording_live_activity_adapter.dart';

/// The localized labels and the formatter a recording's Live Activity is
/// written with, resolved by the UI from `AppLocalizations`, the locale and
/// the unit preference, as the recording screen resolves them.
class RecordingLiveActivityLabels {
  const RecordingLiveActivityLabels({
    required this.formatter,
    required this.numberLocale,
    required this.activityTypes,
    required this.distance,
    required this.pace,
    required this.speed,
    required this.paused,
    required this.autoPaused,
  });

  final ActivityStatsFormatter formatter;

  /// The BCP 47 tag numbers are grouped and rounded for.
  final String numberLocale;

  /// The name of every activity type.
  final Map<ActivityType, String> activityTypes;
  final String distance;
  final String pace;
  final String speed;

  /// Shown while the recording is paused by hand, and [autoPaused] while it
  /// is paused automatically.
  final String paused;
  final String autoPaused;
}

/// Keeps a recording's Live Activity showing the distance and pace or speed
/// of the recording screen.
///
/// Fed every recording state, also while the app is in the background, where
/// the recording screen does not rebuild. Sends content only once [configure]
/// supplied the labels, only for a recording or paused session, and only when
/// the content changed.
class RecordingLiveActivityPublisher {
  RecordingLiveActivityPublisher({
    required RecordingLiveActivityAdapter adapter,
    ActivityStatsCalculator? calculator,
    DiagnosticsRecorder? diagnostics,
  }) : _adapter = adapter,
       _calculator = calculator ?? ActivityStatsCalculator(),
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder();

  final RecordingLiveActivityAdapter _adapter;
  final ActivityStatsCalculator _calculator;
  final DiagnosticsRecorder _diagnostics;

  RecordingLiveActivityLabels? _labels;
  ActivityRecordingState? _state;
  String? _localSessionId;
  RecordingLiveActivityContent? _lastSent;

  /// The stats of the last track, which only changes when a point lands.
  List<ActivityTrackSegment>? _statsSegments;
  ActivityType? _statsActivityType;
  ActivityRecordingStats? _stats;

  /// Supplies the labels, for example after the language or the unit
  /// preference changed, and republishes with them.
  void configure(RecordingLiveActivityLabels labels) {
    _labels = labels;
    _publish();
  }

  /// Publishes [state] of the recording [localSessionId].
  void update(ActivityRecordingState state, {required String? localSessionId}) {
    _state = state;
    _localSessionId = localSessionId;
    _publish();
  }

  void _publish() {
    final labels = _labels;
    final state = _state;
    final localSessionId = _localSessionId;
    if (labels == null ||
        state == null ||
        localSessionId == null ||
        (state.status != ActivityRecordingStatus.recording &&
            state.status != ActivityRecordingStatus.paused)) {
      return;
    }
    final stats = _statsFor(state);
    final formatter = labels.formatter;
    final content = RecordingLiveActivityContent(
      localSessionId: localSessionId,
      title:
          labels.activityTypes[state.activityType] ??
          labels.activityTypes[ActivityType.other]!,
      distanceLabel: labels.distance,
      distanceValue: formatter.formatDistance(
        stats.distanceMeters,
        locale: labels.numberLocale,
      ),
      speedLabel: ActivityStatsFormatter.showsPace(state.activityType)
          ? labels.pace
          : labels.speed,
      speedValue: formatter.formatLivePaceOrSpeed(
        stats,
        activityType: state.activityType,
        locale: labels.numberLocale,
      ),
      pausedLabel: state.isAutoPaused ? labels.autoPaused : labels.paused,
    );
    if (content == _lastSent) {
      return;
    }
    _lastSent = content;
    unawaited(_send(content));
  }

  Future<void> _send(RecordingLiveActivityContent content) async {
    try {
      await _adapter.update(content);
    } catch (error) {
      // The Live Activity only mirrors the recording; a failed update never
      // affects it. Forget what was sent so the next state tries again.
      if (_lastSent == content) {
        _lastSent = null;
      }
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.activityLiveActivityUpdateFailed,
        details: diagnosticErrorDetails(error),
      );
    }
  }

  ActivityRecordingStats _statsFor(ActivityRecordingState state) {
    final segments = state.segments;
    final cached = _stats;
    if (cached != null &&
        identical(segments, _statsSegments) &&
        state.activityType == _statsActivityType) {
      return cached;
    }
    final stats = _calculator.calculate(
      segments,
      activityType: state.activityType,
    );
    _statsSegments = segments;
    _statsActivityType = state.activityType;
    _stats = stats;
    return stats;
  }
}
