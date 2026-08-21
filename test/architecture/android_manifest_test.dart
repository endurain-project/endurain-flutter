import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android declares every Health Connect workout read permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final permissions = RegExp(
      r'<uses-permission\s+android:name="([^"]+)"\s*/>',
    ).allMatches(manifest).map((match) => match.group(1)).toSet();

    expect(
      permissions,
      containsAll(<String>{
        'android.permission.health.READ_EXERCISE',
        'android.permission.health.READ_DISTANCE',
        'android.permission.health.READ_TOTAL_CALORIES_BURNED',
        'android.permission.health.READ_STEPS',
        'android.permission.health.READ_HEART_RATE',
        'android.permission.health.READ_EXERCISE_ROUTES',
        'android.permission.health.READ_HEALTH_DATA_HISTORY',
      }),
    );
    expect(
      permissions,
      isNot(contains('android.permission.health.READ_EXERCISE_ROUTE')),
    );
  });

  test('Android enables user-approved self-hosted cleartext transport', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(manifest, contains('android:usesCleartextTraffic="true"'));
  });

  test('Android references the network security config', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(
      manifest,
      contains('android:networkSecurityConfig="@xml/network_security_config"'),
    );
  });

  test('Android network security config allows self-hosted cleartext but pins '
      'the managed cloud origin to HTTPS', () {
    final config = File(
      'android/app/src/main/res/xml/network_security_config.xml',
    ).readAsStringSync();

    // Self-hosted instances are user-provided hosts that may use plain HTTP.
    expect(config, contains('<base-config cleartextTrafficPermitted="true"'));

    // The managed cloud origin is pinned to HTTPS at the OS layer.
    expect(
      config,
      contains('<domain-config cleartextTrafficPermitted="false"'),
    );
  });

  test('managed cloud origin is pinned to HTTPS on both Android and iOS', () {
    // Defense-in-depth parity guard for the future managed ("Endurain Cloud")
    // service. The managed origin must be reachable over HTTPS only, enforced
    // at the OS layer on BOTH platforms in addition to the Dart transport layer
    // (AppConfig.cloudBaseUrl / ServerUrlResolver). Self-hosted origins stay
    // HTTP-capable via the Android base-config / iOS arbitrary-loads allowance.
    //
    // The pinned host is derived from each platform file rather than hardcoded
    // here, so replacing the placeholder with the real domain on only one
    // platform (and forgetting the other) fails this test.
    final androidConfig = File(
      'android/app/src/main/res/xml/network_security_config.xml',
    ).readAsStringSync();
    final iosPlist = File('ios/Runner/Info.plist').readAsStringSync();

    final androidHost = RegExp(
      r'<domain-config\s+cleartextTrafficPermitted="false">\s*'
      r'<domain[^>]*>([^<]+)</domain>',
    ).firstMatch(androidConfig)?.group(1)?.trim();

    final iosHost = RegExp(
      r'<key>NSExceptionDomains</key>\s*<dict>\s*<key>([^<]+)</key>',
    ).firstMatch(iosPlist)?.group(1)?.trim();

    expect(
      androidHost,
      isNotNull,
      reason:
          'Android must pin a managed host to HTTPS via a '
          'cleartextTrafficPermitted="false" domain-config.',
    );
    expect(androidHost, isNotEmpty);
    expect(
      iosHost,
      isNotNull,
      reason:
          'iOS must pin a managed host to HTTPS via an NSExceptionDomains '
          'entry.',
    );

    // Parity: the identical managed origin must be pinned on both platforms.
    expect(
      iosHost,
      androidHost,
      reason:
          'The managed cloud host pinned to HTTPS must be identical on '
          'Android and iOS. Keep the two OS transport configs in sync.',
    );

    // iOS must actually forbid insecure loads and require modern TLS for the
    // managed host — the presence of the key alone is not sufficient.
    expect(
      iosPlist,
      matches(
        RegExp(r'<key>NSExceptionAllowsInsecureHTTPLoads</key>\s*<false\s*/>'),
      ),
      reason:
          'The managed iOS exception domain must set '
          'NSExceptionAllowsInsecureHTTPLoads to <false/>.',
    );
    expect(
      iosPlist,
      matches(
        RegExp(
          r'<key>NSExceptionMinimumTLSVersion</key>\s*'
          r'<string>TLSv1\.2</string>',
        ),
      ),
      reason: 'The managed iOS exception domain must require TLS 1.2 or newer.',
    );
  });

  test('Android excludes every private activity and health storage root', () {
    for (final path in const [
      'android/app/src/main/res/xml/backup_rules.xml',
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ]) {
      final rules = File(path).readAsStringSync();
      expect(rules, contains('path="activity_records"'));
      expect(rules, contains('path="endurain_private"'));
      expect(rules, contains('path="activity.db"'));
      expect(rules, contains('path="health_import.db"'));
      expect(rules, contains('path="FlutterSecureStorage.xml"'));
      expect(rules, contains('path="FlutterSecureKeyStorage.xml"'));
      expect(rules, contains('path="FlutterSecureStorageConfiguration.xml"'));
      expect(
        rules,
        contains(
          'path="FlutterSecureStorageConfiguration:FlutterSecureStorage.xml"',
        ),
      );
      expect(rules, isNot(contains('path="app_support"')));
    }
  });
}
