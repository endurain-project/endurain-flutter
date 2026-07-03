import 'dart:convert';
import 'dart:io';

import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiagnosticsService', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync(
        'endurain_diagnostics_test_',
      );
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('records sanitized breadcrumbs and errors locally', () async {
      final service = DiagnosticsService(
        supportDirectoryProvider: () async => tempDirectory,
        now: () => DateTime.utc(2026, 6),
      );

      await service.initialize();
      await service.setEnabled(true);
      service.recordBreadcrumbSync(
        DiagnosticsEvents.activityStarted,
        details: {
          'url': 'https://example.test/path?token=secret-token',
          'coordinates': '41.12345, -8.67890',
        },
      );
      service.recordErrorSync(
        StateError(
          'Bearer abc123 at /Users/person/project with 41.12345, -8.67890',
        ),
        StackTrace.fromString('/private/var/containers/example/file.dart:12'),
      );

      final report = await service.readReportText();

      expect(report, isNotNull);
      expect(report, contains(DiagnosticsEvents.activityStarted));
      expect(report, contains('Bearer <redacted>'));
      expect(report, contains('<coordinates>'));
      expect(report, contains('<path>'));
      expect(report, isNot(contains('secret-token')));
      expect(report, isNot(contains('/Users/person')));
      expect(report, isNot(contains('/private/var/containers')));

      final parsedReport = await service.readReport();
      expect(parsedReport, isNotNull);
      expect(parsedReport!.breadcrumbs, hasLength(1));
      expect(parsedReport.errors, hasLength(1));
      expect(
        parsedReport.breadcrumbs.single.event,
        DiagnosticsEvents.activityStarted,
      );
      expect(parsedReport.errors.single.type, 'StateError');
    });

    test('keeps breadcrumbs bounded', () async {
      final service = DiagnosticsService(
        supportDirectoryProvider: () async => tempDirectory,
        maxBreadcrumbs: 2,
      );

      await service.initialize();
      await service.setEnabled(true);
      service.recordBreadcrumbSync('one');
      service.recordBreadcrumbSync('two');
      service.recordBreadcrumbSync('three');

      final report = await service.readReportText();
      final decoded = jsonDecode(report!) as Map<String, dynamic>;
      final breadcrumbs = decoded['breadcrumbs'] as List<dynamic>;

      expect(breadcrumbs, hasLength(2));
      expect(breadcrumbs.first, containsPair('event', 'two'));
      expect(breadcrumbs.last, containsPair('event', 'three'));
    });

    group('redaction security regressions', () {
      const redactionCases = <String, _RedactionCase>{
        'bearer tokens': _RedactionCase(
          input: 'request header Bearer abc123.def-456_ghi end',
          mustNotContain: ['abc123.def-456_ghi'],
          mustContain: 'Bearer <redacted>',
        ),
        'password assignments': _RedactionCase(
          input: 'login failed password=hunter2 retrying',
          mustNotContain: ['hunter2'],
          mustContain: 'password=<redacted>',
        ),
        'secret assignments': _RedactionCase(
          input: 'client secret: s3cr3t-value',
          mustNotContain: ['s3cr3t-value'],
          mustContain: 'secret=<redacted>',
        ),
        'session assignments': _RedactionCase(
          input: 'session=ABCDEF0123456789',
          mustNotContain: ['ABCDEF0123456789'],
          mustContain: 'session=<redacted>',
        ),
        'cookie assignments': _RedactionCase(
          input: 'cookie: sid=topsecretcookie',
          mustNotContain: ['topsecretcookie'],
          mustContain: 'cookie=<redacted>',
        ),
        'query string parameters': _RedactionCase(
          input: 'GET /api/v1?access_token=leaky&user=bob',
          mustNotContain: ['leaky', 'bob'],
          mustContain: '=<redacted>',
        ),
        'home directory paths': _RedactionCase(
          input: 'failed reading /Users/jane/secret/data.gpx',
          mustNotContain: ['/Users/jane'],
          mustContain: '<path>',
        ),
        'ios container paths': _RedactionCase(
          input: 'wrote /private/var/containers/Bundle/file.gpx',
          mustNotContain: ['/private/var/containers'],
          mustContain: '<path>',
        ),
        'gps coordinates': _RedactionCase(
          input: 'position 41.123456, -8.678901 captured',
          mustNotContain: ['41.123456', '-8.678901'],
          mustContain: '<coordinates>',
        ),
      };

      redactionCases.forEach((name, redactionCase) {
        test('redacts $name', () async {
          final service = DiagnosticsService(
            supportDirectoryProvider: () async => tempDirectory,
          );
          await service.initialize();
          await service.setEnabled(true);

          service.recordBreadcrumbSync(
            'security.regression',
            details: {'payload': redactionCase.input},
          );

          final report = await service.readReportText();
          expect(report, isNotNull);
          expect(report, contains(redactionCase.mustContain));
          for (final leaked in redactionCase.mustNotContain) {
            expect(
              report,
              isNot(contains(leaked)),
              reason: '$name leaked "$leaked" into diagnostics report',
            );
          }
        });
      });
    });

    test('clear removes the report', () async {
      final service = DiagnosticsService(
        supportDirectoryProvider: () async => tempDirectory,
      );

      await service.initialize();
      await service.setEnabled(true);
      service.recordBreadcrumbSync('captured');
      await service.clearReport();

      expect(await service.readReportText(), isNull);
    });

    test('does not record while disabled by default', () async {
      final service = DiagnosticsService(
        supportDirectoryProvider: () async => tempDirectory,
      );

      await service.initialize();
      expect(service.isEnabled, isFalse);
      service.recordBreadcrumbSync('ignored');
      service.recordErrorSync(StateError('ignored'), StackTrace.empty);

      expect(await service.readReport(), isNull);
    });

    test('disabling discards the stored report', () async {
      final service = DiagnosticsService(
        supportDirectoryProvider: () async => tempDirectory,
      );

      await service.initialize();
      await service.setEnabled(true);
      service.recordBreadcrumbSync('captured');
      expect(await service.readReport(), isNotNull);

      await service.setEnabled(false);

      expect(service.isEnabled, isFalse);
      expect(await service.readReportText(), isNull);
    });

    test('persists the enabled flag across instances', () async {
      final first = DiagnosticsService(
        supportDirectoryProvider: () async => tempDirectory,
      );
      await first.initialize();
      await first.setEnabled(true);

      final second = DiagnosticsService(
        supportDirectoryProvider: () async => tempDirectory,
      );
      await second.initialize();

      expect(second.isEnabled, isTrue);
      second.recordBreadcrumbSync('captured-after-restart');
      expect(await second.readReport(), isNotNull);
    });
  });
}

class _RedactionCase {
  const _RedactionCase({
    required this.input,
    required this.mustNotContain,
    required this.mustContain,
  });

  final String input;
  final List<String> mustNotContain;
  final String mustContain;
}
