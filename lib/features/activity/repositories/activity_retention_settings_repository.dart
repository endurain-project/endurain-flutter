import 'package:endurain/core/services/secure_storage_service.dart';

class ActivityRetentionSettingsRepository {
  const ActivityRetentionSettingsRepository({required this._storage});

  static const String retainUploadedGpxKey = 'activity_retain_uploaded_gpx';

  final SecureStorageService _storage;

  Future<bool> isRetainUploadedGpxEnabled() async {
    final value = await _storage.read(key: retainUploadedGpxKey);
    return value == null || value == 'true';
  }

  Future<void> setRetainUploadedGpxEnabled(bool enabled) {
    return _storage.write(
      key: retainUploadedGpxKey,
      value: enabled ? 'true' : 'false',
    );
  }
}
