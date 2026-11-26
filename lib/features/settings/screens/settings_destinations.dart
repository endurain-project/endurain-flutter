import 'package:flutter/widgets.dart';

/// The screens the settings list opens, supplied by whoever composes the app.
///
/// Settings is a hub over every feature's configuration screen, but it should
/// not have to know how each one is built or what it depends on. The composition
/// root builds them (with their dependencies) and hands this over, so the list
/// itself stays a plain navigation menu.
class SettingsDestinations {
  const SettingsDestinations({
    required this.serverSettings,
    required this.language,
    required this.units,
    required this.tileServer,
    required this.startCountdown,
    required this.autoPause,
    required this.audioAnnouncements,
    required this.sensors,
    required this.healthSync,
    required this.activityHistory,
    required this.deviceAccess,
    required this.diagnostics,
  });

  final WidgetBuilder serverSettings;
  final WidgetBuilder language;
  final WidgetBuilder units;
  final WidgetBuilder tileServer;
  final WidgetBuilder startCountdown;
  final WidgetBuilder autoPause;
  final WidgetBuilder audioAnnouncements;
  final WidgetBuilder sensors;
  final WidgetBuilder healthSync;
  final WidgetBuilder activityHistory;
  final WidgetBuilder deviceAccess;
  final WidgetBuilder diagnostics;
}
