import 'package:endurain/features/activity/repositories/auto_pause_settings_repository.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

/// Route-owned controller for the auto-pause settings screen.
///
/// Auto-pause only affects the *next* recording (the active config is
/// snapshotted onto the session at start), so unlike the app-lifetime
/// [MeasurementSystemController]-style controllers, this one only needs to
/// exist for the lifetime of the settings screen.
class AutoPauseSettingsController extends SafeNotifier {
  AutoPauseSettingsController({required AutoPauseSettingsRepository repository})
    : _repository = repository;

  final AutoPauseSettingsRepository _repository;

  bool _enabled = true;
  int _delaySeconds = AutoPauseSettingsRepository.defaultDelaySeconds;
  bool _isLoaded = false;

  bool get enabled => _enabled;
  int get delaySeconds => _delaySeconds;
  bool get isLoaded => _isLoaded;

  int get minDelaySeconds => AutoPauseSettingsRepository.minDelaySeconds;
  int get maxDelaySeconds => AutoPauseSettingsRepository.maxDelaySeconds;

  Future<void> load() async {
    try {
      final enabled = await _repository.isEnabled();
      final delaySeconds = await _repository.getDelaySeconds();
      _enabled = enabled;
      _delaySeconds = delaySeconds;
    } catch (_) {
      // Keep the safe defaults on a read failure.
    }
    _isLoaded = true;
    notify();
  }

  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) {
      return;
    }
    _enabled = enabled;
    notify();
    await _repository.setEnabled(enabled);
  }

  Future<void> setDelaySeconds(int seconds) async {
    final clamped = AutoPauseSettingsRepository.clampDelaySeconds(seconds);
    if (_delaySeconds == clamped) {
      return;
    }
    _delaySeconds = clamped;
    notify();
    await _repository.setDelaySeconds(clamped);
  }
}
