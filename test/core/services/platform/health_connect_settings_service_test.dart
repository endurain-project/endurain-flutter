import 'package:endurain/core/services/platform/health_connect_settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('endurain/health_connect_settings');
  var appSettingsCalls = 0;

  PlatformHealthConnectSettingsService build({bool appSettingsResult = true}) =>
      PlatformHealthConnectSettingsService(
        channel: channel,
        openAppSettings: () async {
          appSettingsCalls++;
          return appSettingsResult;
        },
      );

  void handle(Future<Object?> Function(MethodCall call)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  setUp(() => appSettingsCalls = 0);
  tearDown(() => handle(null));

  test('calls openPermissions and reports success without fallback', () async {
    MethodCall? received;
    handle((call) async {
      received = call;
      return true;
    });

    expect(await build().openPermissions(), isTrue);
    expect(received?.method, 'openPermissions');
    expect(received?.arguments, isNull);
    expect(appSettingsCalls, 0);
  });

  test('falls back to the app settings when nothing was launched', () async {
    handle((call) async => false);

    expect(await build().openPermissions(), isTrue);
    expect(appSettingsCalls, 1);
  });

  test('falls back on a null result', () async {
    handle((call) async => null);

    await build().openPermissions();

    expect(appSettingsCalls, 1);
  });

  test('falls back when the channel throws a PlatformException', () async {
    handle((call) async => throw PlatformException(code: 'unavailable'));

    await build().openPermissions();

    expect(appSettingsCalls, 1);
  });

  test('falls back when the plugin is missing', () async {
    handle(null);

    await build().openPermissions();

    expect(appSettingsCalls, 1);
  });

  test('reports false when the fallback also fails', () async {
    handle((call) async => false);

    expect(await build(appSettingsResult: false).openPermissions(), isFalse);
  });

  test('swallows an exception from the fallback', () async {
    handle((call) async => false);
    final service = PlatformHealthConnectSettingsService(
      channel: channel,
      openAppSettings: () async => throw StateError('no settings'),
    );

    expect(await service.openPermissions(), isFalse);
  });
}
