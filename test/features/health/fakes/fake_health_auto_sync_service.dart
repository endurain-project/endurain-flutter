import 'package:endurain/features/health/services/health_auto_sync_service.dart';

/// In-memory fake [HealthAutoSyncService] for controller and screen tests.
class FakeHealthAutoSyncService implements HealthAutoSyncService {
  bool enabled = false;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool enabled) async => this.enabled = enabled;

  @override
  Future<({int imported, int failed})?> syncOnResume() async => null;

  @override
  Future<bool> syncInBackground() async => true;
}
