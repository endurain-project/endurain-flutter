import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/services/app_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('AppServices', () {
    test('default constructor uses AppConfig.defaults', () {
      final services = AppServices();
      expect(services.config, AppConfig.defaults);
      expect(services.config.transportMode, AppTransportMode.selfHosted);
    });

    test('constructor preserves supplied config', () {
      const managed = AppConfig(transportMode: AppTransportMode.managed);
      final services = AppServices(config: managed);
      expect(services.config.transportMode, AppTransportMode.managed);
      expect(services.config.allowInsecureTransport, isFalse);
    });

    test('activityRecordingController can be read without throwing', () {
      final services = AppServices();
      expect(services.activityRecordingController, isNotNull);
    });

    test('createActivityRecordingService returns a service without throwing', () {
      final services = AppServices();
      expect(services.createActivityRecordingService(), isNotNull);
    });
  });
}
