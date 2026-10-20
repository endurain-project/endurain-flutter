import 'package:endurain/features/activity/repositories/auto_pause_settings_repository.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

/// Route-owned controller for the auto-pause settings screen.
///
/// Auto-pause only affects the *next* recording (the active config is
/// snapshotted onto the session at start), so unlike the app-lifetime
/// `MeasurementSystemController`-style controllers, this one only needs to
/// exist for the lifetime of the settings screen.
class AutoPauseSettingsController extends SafeNotifier {
  AutoPauseSettingsController({required AutoPauseSettingsRepository repository})
    : _repository = repository;

  final AutoPauseSettingsRepository _repository;

  bool _enabled = AutoPauseSettingsRepository.defaultEnabled;
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
    final previous = _enabled;
    _enabled = enabled;
    notify();
    try {
      await _repository.setEnabled(enabled);
    } catch (_) {
      if (_enabled == enabled) {
        _enabled = previous;
        notify();
      }
    }
  }

  Future<void> setDelaySeconds(int seconds) async {
    final clamped = AutoPauseSettingsRepository.clampDelaySeconds(seconds);
    if (_delaySeconds == clamped) {
      return;
    }
    final previous = _delaySeconds;
    _delaySeconds = clamped;
    notify();
    try {
      await _repository.setDelaySeconds(clamped);
    } catch (_) {
      if (_delaySeconds == clamped) {
        _delaySeconds = previous;
        notify();
      }
    }
  }
}
