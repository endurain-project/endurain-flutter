import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/services/start_countdown.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:material_ui/material_ui.dart';

/// Seconds added by the "+10 s" button.
const int startCountdownExtraSeconds = 10;

/// Shows a full-screen countdown before a recording starts.
///
/// Resolves with [StartCountdownOutcome.start] when the countdown reaches zero
/// or the user taps "Start now", and with [StartCountdownOutcome.cancel] when
/// they tap Cancel or go back. [onCue] receives each of the last seconds so the
/// caller can speak them.
Future<StartCountdownOutcome> showStartCountdownDialog(
  BuildContext context, {
  required int seconds,
  required ActivityType activityType,
  void Function(int secondsLeft)? onCue,
  DateTime Function()? now,
}) async {
  // The root navigator, so the countdown also covers the tab bar.
  final outcome = await Navigator.of(context, rootNavigator: true)
      .push<StartCountdownOutcome>(
        PageRouteBuilder<StartCountdownOutcome>(
          opaque: true,
          fullscreenDialog: true,
          pageBuilder: (context, _, _) => StartCountdownView(
            seconds: seconds,
            activityType: activityType,
            onCue: onCue,
            now: now,
          ),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
  return outcome ?? StartCountdownOutcome.cancel;
}

/// The countdown screen pushed by [showStartCountdownDialog].
class StartCountdownView extends StatefulWidget {
  const StartCountdownView({
    super.key,
    required this.seconds,
    required this.activityType,
    this.onCue,
    this.now,
  });

  final int seconds;
  final ActivityType activityType;
  final void Function(int secondsLeft)? onCue;
  final DateTime Function()? now;

  @override
  State<StartCountdownView> createState() => _StartCountdownViewState();
}

class _StartCountdownViewState extends State<StartCountdownView> {
  late final StartCountdown _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = StartCountdown(
      seconds: widget.seconds,
      onCue: widget.onCue,
      now: widget.now,
    );
    _countdown.addListener(_onCountdownChanged);
    _countdown.outcome.then(_close);
    _countdown.start();
  }

  void _onCountdownChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _close(StartCountdownOutcome outcome) {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(outcome);
  }

  @override
  void dispose() {
    _countdown.removeListener(_onCountdownChanged);
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isApple = PlatformUtils.isApplePlatform;
    final background = isApple
        ? CupertinoDynamicColor.resolve(
            CupertinoColors.systemBackground,
            context,
          )
        : Theme.of(context).colorScheme.surface;
    final foreground = isApple
        ? CupertinoDynamicColor.resolve(CupertinoColors.label, context)
        : Theme.of(context).colorScheme.onSurface;
    final secondary = isApple
        ? CupertinoDynamicColor.resolve(CupertinoColors.secondaryLabel, context)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final remaining = _countdown.remainingSeconds;

    return PopScope<StartCountdownOutcome>(
      canPop: _countdown.isFinished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _countdown.cancel();
        }
      },
      // Material (not a bare ColoredBox) so the Material buttons have an ink
      // ancestor on Android.
      child: Material(
        color: background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.paddingStandard),
            child: DefaultTextStyle(
              style: TextStyle(color: foreground, fontSize: 17),
              textAlign: TextAlign.center,
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    widget.activityType.localizedLabel(l10n),
                    style: TextStyle(color: secondary, fontSize: 20),
                  ),
                  const SizedBox(height: UIConstants.paddingStandard),
                  Text(l10n.activityStartCountdownTitle),
                  Semantics(
                    liveRegion: true,
                    label: l10n.activityStartCountdownRemaining(remaining),
                    excludeSemantics: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$remaining',
                        key: const ValueKey('startCountdownRemaining'),
                        style: TextStyle(
                          color: foreground,
                          fontSize: 160,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  AdaptiveButton(
                    key: const ValueKey('startCountdownStartNow'),
                    label: l10n.activityStartCountdownStartNow,
                    onPressed: _countdown.skip,
                    expand: true,
                    icon: const AdaptiveIcon(
                      materialIcon: Icons.play_arrow,
                      cupertinoIcon: CupertinoIcons.play_arrow_solid,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: AdaptiveButton(
                          key: const ValueKey('startCountdownCancel'),
                          label: l10n.cancel,
                          onPressed: _countdown.cancel,
                          variant: AdaptiveButtonVariant.secondary,
                          expand: true,
                        ),
                      ),
                      const SizedBox(width: UIConstants.paddingMedium),
                      Expanded(
                        child: AdaptiveButton(
                          key: const ValueKey('startCountdownAddTime'),
                          label: l10n.activityStartCountdownAddSeconds(
                            startCountdownExtraSeconds,
                          ),
                          onPressed: () =>
                              _countdown.addSeconds(startCountdownExtraSeconds),
                          variant: AdaptiveButtonVariant.secondary,
                          expand: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
