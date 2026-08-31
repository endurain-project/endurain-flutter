import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_config.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';
import 'package:endurain/features/activity/repositories/audio_announcement_settings_repository.dart';
import 'package:endurain/features/activity/services/audio_announcement_preview_adapter.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

/// App-lifetime controller for the audio-announcement preferences.
///
/// Mirrors `MeasurementSystemController`: owned by the composition root so the
/// settings screen and the active-recording wiring (which reads the interval
/// for the selected activity type at recording start) always observe the same
/// value.
class AudioAnnouncementSettingsController extends SafeNotifier {
  AudioAnnouncementSettingsController({
    required AudioAnnouncementSettingsRepository repository,
    AudioAnnouncementPreviewAdapter previewAdapter =
        const UnsupportedAudioAnnouncementPreviewAdapter(),
  }) : _repository = repository,
       _previewAdapter = previewAdapter;

  final AudioAnnouncementSettingsRepository _repository;
  final AudioAnnouncementPreviewAdapter _previewAdapter;

  AudioAnnouncementSettings _settings = AudioAnnouncementSettings.defaults();
  bool _isLoaded = false;

  AudioAnnouncementSettings get settings => _settings;

  /// Whether the persisted preference has been read yet.
  bool get isLoaded => _isLoaded;

  /// Loads the persisted preference. On any read error the app falls back to
  /// [AudioAnnouncementSettings.defaults].
  Future<void> load() async {
    try {
      _settings = await _repository.getSettings();
    } catch (_) {
      _settings = AudioAnnouncementSettings.defaults();
    }
    _isLoaded = true;
    notify();
  }

  Future<void> setMasterEnabled(bool enabled) async {
    if (_settings.masterEnabled == enabled) {
      return;
    }
    _settings = _settings.copyWith(masterEnabled: enabled);
    notify();
    await _repository.setSettings(_settings);
  }

  Future<void> setDuckOtherAudio(bool duck) async {
    if (_settings.duckOtherAudio == duck) {
      return;
    }
    _settings = _settings.copyWith(duckOtherAudio: duck);
    notify();
    await _repository.setSettings(_settings);
  }

  Future<void> setInterval(
    ActivityType type,
    AudioAnnouncementInterval interval,
  ) async {
    if (_settings.intervalFor(type) == interval) {
      return;
    }
    _settings = _settings.withInterval(type, interval);
    notify();
    await _repository.setSettings(_settings);
  }

  /// Speaks one sample announcement built from [config].
  ///
  /// Returns `false` when the platform rejected the request, which is the only
  /// signal the user gets that announcements will not be audible: every native
  /// speech failure is otherwise swallowed so it can never fail a recording.
  Future<bool> speakPreview(AudioAnnouncementConfig config) async {
    try {
      await _previewAdapter.speakPreview(config);
      return true;
    } catch (_) {
      return false;
    }
  }
}
