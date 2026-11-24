import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiagnosticsService', () {
    late Directory tempDirectory;
    late List<DiagnosticsService> services;

    DiagnosticsService createService({
      DateTime Function()? now,
      int maxBreadcrumbs = 40,
    }) {
      final service = DiagnosticsService(
        supportDirectoryProvider: () async => tempDirectory,
        now: now,
        maxBreadcrumbs: maxBreadcrumbs,
      );
      services.add(service);
      return service;
    }

    setUp(() {
      services = [];
      tempDirectory = Directory.systemTemp.createTempSync(
        'endurain_diagnostics_test_',
      );
    });

    tearDown(() async {
      for (final service in services) {
        await service.flush();
      }
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('records sanitized breadcrumbs and errors locally', () async {
      final service = createService(now: () => DateTime.utc(2026, 6));

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
      final service = createService(maxBreadcrumbs: 2);

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
        'android app data paths (data/user)': _RedactionCase(
          input: 'wrote /data/user/0/com.app/track.gpx',
          mustNotContain: ['/data/user/0/com.app'],
          mustContain: '<path>',
        ),
        'android app data paths (data/data)': _RedactionCase(
          input: 'reading /data/data/com.app/app.db',
          mustNotContain: ['/data/data/com.app'],
          mustContain: '<path>',
        ),
        'android external storage paths': _RedactionCase(
          input: 'export /storage/emulated/0/track.gpx',
          mustNotContain: ['/storage/emulated/0'],
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
          final service = createService();
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
      final service = createService();

      await service.initialize();
      await service.setEnabled(true);
      service.recordBreadcrumbSync('captured');
      await service.clearReport();

      expect(await service.readReportText(), isNull);
    });

    test('does not record while disabled by default', () async {
      final service = createService();

      await service.initialize();
      expect(service.isEnabled, isFalse);
      service.recordBreadcrumbSync('ignored');
      service.recordErrorSync(StateError('ignored'), StackTrace.empty);

      expect(await service.readReport(), isNull);
    });

    test('disabling discards the stored report', () async {
      final service = createService();

      await service.initialize();
      await service.setEnabled(true);
      service.recordBreadcrumbSync('captured');
      expect(await service.readReport(), isNotNull);

      await service.setEnabled(false);

      expect(service.isEnabled, isFalse);
      expect(await service.readReportText(), isNull);
    });

    test('persists the enabled flag across instances', () async {
      final first = createService();
      await first.initialize();
      await first.setEnabled(true);

      final second = createService();
      await second.initialize();

      expect(second.isEnabled, isTrue);
      second.recordBreadcrumbSync('captured-after-restart');
      expect(await second.readReport(), isNotNull);
    });

    test('buffers breadcrumbs and persists them to disk on flush', () async {
      final first = createService();
      await first.initialize();
      await first.setEnabled(true);
      first.recordBreadcrumbSync('buffered.event');

      // Force the coalesced async write, then read from a fresh instance so
      // the assertion only passes if the breadcrumb actually reached disk.
      await first.flush();

      final second = createService();
      await second.initialize();
      final report = await second.readReport();

      expect(report, isNotNull);
      expect(
        report!.breadcrumbs.map((breadcrumb) => breadcrumb.event),
        contains('buffered.event'),
      );
    });

    test('persists errors synchronously without an explicit flush', () async {
      final first = createService();
      await first.initialize();
      await first.setEnabled(true);
      first.recordErrorSync(StateError('boom'), StackTrace.empty);

      // No flush(): a fresh instance must still see the error, proving errors
      // are written synchronously so crash context survives a hard termination.
      final second = createService();
      await second.initialize();
      final report = await second.readReport();

      expect(report, isNotNull);
      expect(report!.errors.single.type, 'StateError');
    });

    test('writes leave the report whole and no staging files', () async {
      final first = createService();
      await first.initialize();
      await first.setEnabled(true);
      first.recordBreadcrumbSync('async.event');
      await first.flush();
      first.recordErrorSync(StateError('boom'), StackTrace.empty);

      final names = tempDirectory
          .listSync()
          .map((entity) => entity.uri.pathSegments.last)
          .toList();
      expect(names, ['endurain_diagnostics.json']);
    });

    test(
      'a write killed before its rename keeps the opt-in on restart',
      () async {
        final first = createService();
        await first.initialize();
        await first.setEnabled(true);
        first.recordBreadcrumbSync('before.kill');
        await first.flush();

        // What a process killed mid-write leaves: a truncated staging file
        // beside the last complete report.
        File('${tempDirectory.path}/endurain_diagnostics.json.async.tmp')
            .writeAsStringSync('{"schemaVersion": 1, "enab');

        final second = createService();
        await second.initialize();

        expect(second.isEnabled, isTrue);
        final report = await second.readReport();
        expect(
          report!.breadcrumbs.map((breadcrumb) => breadcrumb.event),
          contains('before.kill'),
        );
      },
    );

    test('disabling also removes leftover staging files', () async {
      final service = createService();
      await service.initialize();
      await service.setEnabled(true);
      File('${tempDirectory.path}/endurain_diagnostics.json.sync.tmp')
          .writeAsStringSync('partial');

      await service.setEnabled(false);

      expect(tempDirectory.listSync(), isEmpty);
    });

    test('an error stays on disk while an older breadcrumb write lands', () async {
      final service = createService();
      await service.initialize();
      await service.setEnabled(true);
      final report = File('${tempDirectory.path}/endurain_diagnostics.json');

      // The breadcrumb starts an async write that snapshots the report without
      // the error; the error is then written synchronously mid-flight.
      service
        ..recordBreadcrumbSync('before.error')
        ..recordErrorSync(StateError('boom'), StackTrace.empty);

      var flushed = false;
      unawaited(service.flush().then((_) => flushed = true));
      while (!flushed) {
        final payload =
            jsonDecode(report.readAsStringSync()) as Map<String, dynamic>;
        expect(payload['errors'], isNotEmpty);
        await Future<void>.delayed(Duration.zero);
      }
      final payload =
          jsonDecode(report.readAsStringSync()) as Map<String, dynamic>;
      expect(payload['errors'], hasLength(1));
      expect(
        (payload['breadcrumbs'] as List).map((b) => (b as Map)['event']),
        contains('before.error'),
      );
    });

    test('folds consecutive lifecycle changes into one breadcrumb', () async {
      final service = createService();
      await service.initialize();
      await service.setEnabled(true);

      for (final state in ['inactive', 'hidden', 'paused']) {
        service.recordBreadcrumbSync(
          DiagnosticsEvents.appLifecycleChanged,
          details: {'state': state},
        );
      }
      service.recordBreadcrumbSync('between');
      service.recordBreadcrumbSync(
        DiagnosticsEvents.appLifecycleChanged,
        details: {'state': 'resumed'},
      );

      final breadcrumbs = (await service.readReport())!.breadcrumbs;
      expect(breadcrumbs.map((b) => b.event), [
        DiagnosticsEvents.appLifecycleChanged,
        'between',
        DiagnosticsEvents.appLifecycleChanged,
      ]);
      expect(breadcrumbs.first.details['state'], 'paused');
      expect(breadcrumbs.first.details['trail'], 'inactive>hidden>paused');
      expect(breadcrumbs.first.details['lastAt'], isNotNull);
      expect(breadcrumbs.last.details, {'state': 'resumed'});
    });

    test('caps a long lifecycle trail', () async {
      final service = createService();
      await service.initialize();
      await service.setEnabled(true);

      for (var i = 0; i < 40; i++) {
        service.recordBreadcrumbSync(
          DiagnosticsEvents.appLifecycleChanged,
          details: {'state': i.isEven ? 'paused' : 'resumed'},
        );
      }

      final report = (await service.readReport())!;
      final trail = report.breadcrumbs.single.details['trail']! as String;
      expect(trail.split('>'), hasLength(16));
      expect(trail, startsWith('…>'));
    });

    test('writes the launch context into the report header', () async {
      final first = createService();
      await first.initialize();
      await first.setEnabled(true);
      first
        ..setContext({
          'appVersion': '1.2.3+4',
          'osVersion': 'path /Users/person/secret',
        })
        ..recordBreadcrumbSync('event');
      await first.flush();

      final second = createService();
      await second.initialize();
      final report = (await second.readReport())!;

      expect(report.context['appVersion'], '1.2.3+4');
      expect(report.context['osVersion'], isNot(contains('/Users/person')));
      expect(report.schemaVersion, 2);
    });

    test('error details carry the code, status and cause type only', () {
      expect(
        diagnosticErrorDetails(
          const AppException(
            AppErrorCode.tokenExchangeFailed,
            details: 'server text',
            statusCode: 401,
            cause: FormatException('secret'),
          ),
        ),
        {
          'type': 'AppException',
          'code': 'tokenExchangeFailed',
          'status': 401,
          'cause': 'FormatException',
        },
      );
      expect(diagnosticErrorDetails(StateError('boom')), {
        'type': 'StateError',
      });
    });

    test('flush is a safe no-op while disabled', () async {
      final service = createService();
      await service.initialize();

      await service.flush();

      expect(service.isEnabled, isFalse);
      expect(await service.readReport(), isNull);
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
