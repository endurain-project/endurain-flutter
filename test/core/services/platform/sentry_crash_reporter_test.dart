import 'package:endurain/core/services/platform/sentry_crash_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry/sentry.dart';

void main() {
  group('SentryCrashReporter.scrubEvent', () {
    final reporter = SentryCrashReporter();

    Future<SentryEvent> scrub(SentryEvent event) async {
      final result = await reporter.scrubEvent(event, Hint());
      return result!;
    }

    test('redacts exception values, message and tags', () async {
      final event = SentryEvent(
        exceptions: [SentryException(type: 'E', value: 'token=abc123 failed')],
        message: SentryMessage(
          'password=hunter2',
          template: 'Bearer abc.def',
          params: ['x'],
        ),
        tags: {'source': 'secret=shh'},
      );

      final scrubbed = await scrub(event);

      expect(scrubbed.exceptions!.single.value, isNot(contains('abc123')));
      expect(scrubbed.message!.formatted, isNot(contains('hunter2')));
      expect(scrubbed.message!.template, isNot(contains('abc.def')));
      expect(scrubbed.message!.params, isNull);
      expect(scrubbed.tags!['source'], isNot(contains('shh')));
    });

    test('drops request, user, extras and breadcrumbs', () async {
      final event = SentryEvent(
        request: SentryRequest(url: 'https://example.test/?token=abc'),
        user: SentryUser(id: '1', email: 'a@b.c'),
        breadcrumbs: [Breadcrumb(message: 'secret')],
        // ignore: deprecated_member_use
        extra: {'k': 'v'},
      );

      final scrubbed = await scrub(event);

      expect(scrubbed.request, isNull);
      expect(scrubbed.user, isNull);
      expect(scrubbed.breadcrumbs, isNull);
      // ignore: deprecated_member_use
      expect(scrubbed.extra, isNull);
    });

    test('keeps only allow-listed contexts', () async {
      final event = SentryEvent(
        contexts: Contexts()
          ..['device'] = SentryDevice(name: 'phone')
          ..['os'] = SentryOperatingSystem(name: 'iOS')
          ..['culture'] = SentryCulture(locale: 'en')
          ..['custom'] = {'a': 1},
      );

      final scrubbed = await scrub(event);

      expect(scrubbed.contexts.keys, containsAll(['device', 'os']));
      expect(scrubbed.contexts.keys, isNot(contains('culture')));
      expect(scrubbed.contexts.keys, isNot(contains('custom')));
    });
  });
}
