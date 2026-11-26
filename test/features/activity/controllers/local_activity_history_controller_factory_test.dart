import 'package:endurain/app/app_services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('AppServices.createLocalActivityHistoryController', () {
    test('returns a new route-owned controller on every call', () {
      final services = AppServices();

      // Each history or details route owns and disposes its controller, so two
      // routes must never share one: closing the first would tear down the
      // second's.
      final first = services.createLocalActivityHistoryController();
      final second = services.createLocalActivityHistoryController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      expect(identical(first, second), isFalse);
    });
  });
}
