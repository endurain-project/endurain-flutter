import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:flutter/widgets.dart';

/// Makes the app's [DiagnosticsRecorder] reachable from shared UI code
/// (dialogs, adaptive widgets) that sits below the app layer and so cannot use
/// `AppScope`.
class DiagnosticsScope extends InheritedWidget {
  const DiagnosticsScope({
    super.key,
    required this.recorder,
    required super.child,
  });

  final DiagnosticsRecorder recorder;

  /// The ambient recorder, or a no-op one when there is no scope (widget tests
  /// that do not provide one). Diagnostics are never load-bearing, so a
  /// missing scope must not fail the caller.
  static DiagnosticsRecorder of(BuildContext context) {
    final scope =
        context
                .getElementForInheritedWidgetOfExactType<DiagnosticsScope>()
                ?.widget
            as DiagnosticsScope?;
    return scope?.recorder ?? const NoopDiagnosticsRecorder();
  }

  @override
  bool updateShouldNotify(DiagnosticsScope oldWidget) =>
      recorder != oldWidget.recorder;
}
