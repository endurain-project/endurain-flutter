import 'package:endurain/core/services/app_preferences_store.dart';

/// An in-memory [AppPreferencesStore] for use in widget tests.
class FakePreferencesStore extends AppPreferencesStore {
  FakePreferencesStore() : super(backend: _InMemoryPreferencesBackend());
}

class _InMemoryPreferencesBackend implements AppPreferencesBackend {
  final Map<String, String> _map = {
    'endurain.preferences_json_migration_complete': 'true',
  };

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async {
    _map[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _map.remove(key);
  }
}
