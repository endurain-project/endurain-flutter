import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android declares the Health Connect route read permission', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final permissions = RegExp(
      r'<uses-permission\s+android:name="([^"]+)"\s*/>',
    ).allMatches(manifest).map((match) => match.group(1)).toSet();

    expect(
      permissions,
      contains('android.permission.health.READ_EXERCISE_ROUTES'),
    );
    expect(
      permissions,
      isNot(contains('android.permission.health.READ_EXERCISE_ROUTE')),
    );
  });

  test('Android enables user-approved self-hosted cleartext transport', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:usesCleartextTraffic="true"'));
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
