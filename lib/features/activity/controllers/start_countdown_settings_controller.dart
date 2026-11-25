import 'package:endurain/features/activity/repositories/start_countdown_settings_repository.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

/// Route-owned state for the start-countdown settings screen.
///
/// The preference is read fresh each time Start is tapped, so this controller
/// only lives as long as the settings screen. Writes are optimistic and roll
/// back when persisting fails.
class StartCountdownSettingsController extends SafeNotifier {
  StartCountdownSettingsController({
    required StartCountdownSettingsRepository repository,
  }) : _repository = repository;

  final StartCountdownSettingsRepository _repository;

  bool _enabled = StartCountdownSettingsRepository.defaultEnabled;
  int _seconds = StartCountdownSettingsRepository.defaultSeconds;
  bool _voiceEnabled = StartCountdownSettingsRepository.defaultVoiceEnabled;
  bool _isLoaded = false;

  bool get enabled => _enabled;
  int get seconds => _seconds;
  bool get voiceEnabled => _voiceEnabled;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    try {
      final enabled = await _repository.isEnabled();
      final seconds = await _repository.getSeconds();
      final voiceEnabled = await _repository.isVoiceEnabled();
      _enabled = enabled;
      _seconds = seconds;
      _voiceEnabled = voiceEnabled;
    } catch (_) {
      // Keep the defaults on a read failure.
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

  Future<void> setSeconds(int seconds) async {
    final clamped = StartCountdownSettingsRepository.clampSeconds(seconds);
    if (_seconds == clamped) {
      return;
    }
    final previous = _seconds;
    _seconds = clamped;
    notify();
    try {
      await _repository.setSeconds(clamped);
    } catch (_) {
      if (_seconds == clamped) {
        _seconds = previous;
        notify();
      }
    }
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    if (_voiceEnabled == enabled) {
      return;
    }
    final previous = _voiceEnabled;
    _voiceEnabled = enabled;
    notify();
    try {
      await _repository.setVoiceEnabled(enabled);
    } catch (_) {
      if (_voiceEnabled == enabled) {
        _voiceEnabled = previous;
        notify();
      }
    }
  }
}
