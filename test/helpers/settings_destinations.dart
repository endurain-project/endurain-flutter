import 'package:endurain/features/settings/screens/settings_destinations.dart';
import 'package:flutter/widgets.dart';

/// [SettingsDestinations] whose pages are empty placeholders, for tests that
/// exercise the settings list itself rather than the pages it opens.
///
/// Pass the entries a test cares about to replace them.
SettingsDestinations placeholderSettingsDestinations({
  WidgetBuilder? serverSettings,
  WidgetBuilder? language,
  WidgetBuilder? units,
  WidgetBuilder? tileServer,
  WidgetBuilder? startCountdown,
  WidgetBuilder? autoPause,
  WidgetBuilder? audioAnnouncements,
  WidgetBuilder? sensors,
  WidgetBuilder? healthSync,
  WidgetBuilder? activityHistory,
  WidgetBuilder? deviceAccess,
  WidgetBuilder? diagnostics,
}) {
  Widget placeholder(BuildContext context) => const SizedBox();
  return SettingsDestinations(
    serverSettings: serverSettings ?? placeholder,
    language: language ?? placeholder,
    units: units ?? placeholder,
    tileServer: tileServer ?? placeholder,
    startCountdown: startCountdown ?? placeholder,
    autoPause: autoPause ?? placeholder,
    audioAnnouncements: audioAnnouncements ?? placeholder,
    sensors: sensors ?? placeholder,
    healthSync: healthSync ?? placeholder,
    activityHistory: activityHistory ?? placeholder,
    deviceAccess: deviceAccess ?? placeholder,
    diagnostics: diagnostics ?? placeholder,
  );
}
