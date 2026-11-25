import 'package:endurain/features/activity/repositories/start_countdown_settings_repository.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

/// Route-owned state for the start-countdown settings screen.
///
/// The preference is read fresh each time Start is tapped, so this controller
/// only lives as long as the settings screen. Changes show at once and are
/// saved in order, one at a time per preference. Once every save has settled
/// the screen shows the last value that was actually saved, even when a
/// save in between failed.
class StartCountdownSettingsController extends SafeNotifier {
  StartCountdownSettingsController({
    required StartCountdownSettingsRepository repository,
  }) : _repository = repository;

  final StartCountdownSettingsRepository _repository;

  final _Preference<bool> _enabled = _Preference(
    StartCountdownSettingsRepository.defaultEnabled,
  );
  final _Preference<int> _seconds = _Preference(
    StartCountdownSettingsRepository.defaultSeconds,
  );
  final _Preference<bool> _voiceEnabled = _Preference(
    StartCountdownSettingsRepository.defaultVoiceEnabled,
  );
  bool _isLoaded = false;

  bool get enabled => _enabled.shown;
  int get seconds => _seconds.shown;
  bool get voiceEnabled => _voiceEnabled.shown;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    try {
      final enabled = await _repository.isEnabled();
      final seconds = await _repository.getSeconds();
      final voiceEnabled = await _repository.isVoiceEnabled();
      _enabled.loaded(enabled);
      _seconds.loaded(seconds);
      _voiceEnabled.loaded(voiceEnabled);
    } catch (_) {
      // Keep the defaults on a read failure.
    }
    _isLoaded = true;
    notify();
  }

  Future<void> setEnabled(bool enabled) =>
      _save(_enabled, enabled, _repository.setEnabled);

  Future<void> setSeconds(int seconds) => _save(
    _seconds,
    StartCountdownSettingsRepository.clampSeconds(seconds),
    _repository.setSeconds,
  );

  Future<void> setVoiceEnabled(bool enabled) =>
      _save(_voiceEnabled, enabled, _repository.setVoiceEnabled);

  Future<void> _save<T>(
    _Preference<T> preference,
    T value,
    Future<void> Function(T value) write,
  ) {
    if (preference.shown == value) {
      return preference.pending ?? Future<void>.value();
    }
    preference.shown = value;
    final request = ++preference.requests;
    notify();
    Future<void> save() async {
      try {
        await write(value);
        preference.saved = value;
      } catch (_) {
        // Rolled back below once no newer change is queued.
      }
      if (request == preference.requests &&
          preference.shown != preference.saved) {
        preference.shown = preference.saved;
        notify();
      }
    }

    final previous = preference.pending;
    final next = previous == null ? save() : previous.then((_) => save());
    preference.pending = next;
    return next;
  }
}

/// One preference: what the screen shows, what storage holds, and the queue
/// of saves still running.
class _Preference<T> {
  _Preference(T initial) : shown = initial, saved = initial;

  T shown;
  T saved;
  int requests = 0;

  /// The last queued save; null before the first one.
  Future<void>? pending;

  void loaded(T value) {
    shown = value;
    saved = value;
  }
}
