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

  test('Android network security config allows self-hosted cleartext', () {
    final config = File(
      'android/app/src/main/res/xml/network_security_config.xml',
    ).readAsStringSync();

    // Self-hosted instances are user-provided hosts that may use plain HTTP.
    expect(config, contains('<base-config cleartextTrafficPermitted="true"'));
  });

  test('OS-level managed-origin pinning matches the build configuration', () {
    // A build that targets the managed ("Endurain Cloud") service must pin that
    // origin to HTTPS at the OS layer on BOTH platforms, in addition to the
    // Dart transport check (AppConfig.cloudBaseUrl / ServerUrlResolver). With
    // no managed origin configured, neither platform may pin a host: a pinned
    // placeholder reads as enforcement while enforcing nothing.
    final managedOrigin = _configuredManagedOrigin();

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

    if (managedOrigin == null) {
      expect(
        androidHost,
        isNull,
        reason:
            'No ENDURAIN_CLOUD_BASE_URL is configured for this build, so '
            'network_security_config.xml must not pin a managed host.',
      );
      expect(
        iosHost,
        isNull,
        reason:
            'No ENDURAIN_CLOUD_BASE_URL is configured for this build, so '
            'Info.plist must not declare an NSExceptionDomains entry.',
      );
      return;
    }

    final expectedHost = Uri.tryParse(managedOrigin)?.host ?? '';
    expect(
      expectedHost,
      isNotEmpty,
      reason:
          'ENDURAIN_CLOUD_BASE_URL must be an absolute origin URL, '
          'e.g. https://app.example.com.',
    );

    expect(
      androidHost,
      expectedHost,
      reason:
          'network_security_config.xml must pin the configured managed host '
          'to HTTPS via a cleartextTrafficPermitted="false" domain-config.',
    );
    expect(
      iosHost,
      expectedHost,
      reason:
          'Info.plist must pin the configured managed host to HTTPS via an '
          'NSExceptionDomains entry. Keep both OS transport configs in sync.',
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

/// The managed ("Endurain Cloud") origin this build targets, or `null` when it
/// targets self-hosted instances only.
String? _configuredManagedOrigin() {
  const origin = String.fromEnvironment('ENDURAIN_CLOUD_BASE_URL');
  return origin.isEmpty ? null : origin;
}
