import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ActivityUploadService ingestion job polling', () {
    test('polls the job after a 202 until it completes', () async {
      final fetched = <String>[];
      final service = _service(
        uploadBody: {'id': 'job 1', 'status': 'queued'},
        jobs: [
          {'id': 'job 1', 'status': 'queued', 'finished_at': null},
          {'id': 'job 1', 'status': 'running', 'finished_at': null},
          {
            'id': 'job 1',
            'status': 'succeeded',
            'finished_at': '2026-10-19T21:14:33Z',
            'error_code': null,
            'files_failed': 0,
          },
        ],
        onFetch: fetched.add,
      );

      await service.uploadGpx(_request());

      expect(fetched, hasLength(3));
      expect(fetched.first, '/jobs/job%201');
    });

    test('keeps polling on a status it does not recognize', () async {
      var fetches = 0;
      final service = _service(
        uploadBody: {'id': 'job-1'},
        jobs: [
          {
            'id': 'job-1',
            'status': 'queued_for_review',
            'finished_at': '2026-10-19T21:14:33Z',
          },
        ],
        maxPolls: 2,
        onFetch: (_) => fetches++,
      );

      await expectLater(
        service.uploadGpx(_request()),
        throwsA(
          isA<AppException>().having(
            (e) => e.cause,
            'cause',
            isA<TimeoutException>(),
          ),
        ),
      );
      expect(fetches, 2);
    });

    test('fails permanently with the job error code', () async {
      final service = _service(
        uploadBody: {'id': 'job-1'},
        jobs: [
          {
            'id': 'job-1',
            'status': 'failed',
            'error_code': 'unsupported_format',
            'finished_at': '2026-10-19T21:14:33Z',
          },
        ],
      );

      await expectLater(
        service.uploadGpx(_request()),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', AppErrorCode.activityUploadFailed)
              .having((e) => e.details, 'details', 'unsupported_format')
              .having((e) => e.cause, 'cause', isNull),
        ),
      );
    });

    test('fails when files failed even if succeeded', () async {
      final service = _service(
        uploadBody: {'id': 'job-1'},
        jobs: [
          {
            'id': 'job-1',
            'status': 'succeeded',
            'finished_at': '2026-10-19T21:14:33Z',
            'files_failed': 1,
          },
        ],
      );

      await expectLater(
        service.uploadGpx(_request()),
        throwsA(isA<AppException>()),
      );
    });

    test('times out with a transient cause when the job never ends', () async {
      var fetches = 0;
      final service = _service(
        uploadBody: {'id': 'job-1'},
        jobs: [
          {'id': 'job-1', 'status': 'queued', 'finished_at': null},
        ],
        maxPolls: 3,
        onFetch: (_) => fetches++,
      );

      await expectLater(
        service.uploadGpx(_request()),
        throwsA(
          isA<AppException>().having(
            (e) => e.cause,
            'cause',
            isA<TimeoutException>(),
          ),
        ),
      );
      expect(fetches, 3);
    });

    test('keeps polling through a transient status check error', () async {
      var fetches = 0;
      final service = _service(
        uploadBody: {'id': 'job-1'},
        jobs: const [],
        fetch: (_) async {
          fetches++;
          if (fetches == 1) {
            throw const AppException(
              AppErrorCode.activityUploadFailed,
              statusCode: 503,
            );
          }
          if (fetches == 2) {
            throw const SocketException('offline');
          }
          return {
            'id': 'job-1',
            'status': 'succeeded',
            'finished_at': '2026-10-19T21:14:33Z',
          };
        },
      );

      await service.uploadGpx(_request());

      expect(fetches, 3);
    });

    test('stops on a permanent status check error', () async {
      var fetches = 0;
      final service = _service(
        uploadBody: {'id': 'job-1'},
        jobs: const [],
        fetch: (_) async {
          fetches++;
          throw const AppException(
            AppErrorCode.activityUploadFailed,
            statusCode: 404,
          );
        },
      );

      await expectLater(
        service.uploadGpx(_request()),
        throwsA(isA<AppException>().having((e) => e.statusCode, 'status', 404)),
      );
      expect(fetches, 1);
    });

    test('stops when the session expired during a status check', () async {
      final service = _service(
        uploadBody: {'id': 'job-1'},
        jobs: const [],
        fetch: (_) async =>
            throw const AppException(AppErrorCode.sessionExpired),
      );

      await expectLater(
        service.uploadGpx(_request()),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.sessionExpired,
          ),
        ),
      );
    });

    test('does not poll when the 202 body has no job id', () async {
      var fetches = 0;
      final service = _service(
        uploadBody: <String, Object?>{},
        jobs: const [],
        onFetch: (_) => fetches++,
      );

      await service.uploadGpx(_request());

      expect(fetches, 0);
    });

    test('does not poll for a non-202 success', () async {
      var fetches = 0;
      final service = _service(
        uploadStatus: 200,
        uploadBody: {'id': 'job-1'},
        jobs: const [],
        onFetch: (_) => fetches++,
      );

      await service.uploadGpx(_request());

      expect(fetches, 0);
    });
    test(
      'polls the Content-Location of the 202 when it is a job path',
      () async {
        final fetched = <String>[];
        final service = _service(
          uploadBody: {'id': 'job-1'},
          uploadHeaders: {'content-location': '/api/v1/jobs/job-from-header'},
          jobs: [
            {'id': 'job-1', 'status': 'succeeded'},
          ],
          onFetch: fetched.add,
        );

        await service.uploadGpx(_request());

        expect(fetched, ['/api/v1/jobs/job-from-header']);
      },
    );

    test('ignores a Content-Location that is not a job path', () async {
      final fetched = <String>[];
      final service = _service(
        uploadBody: {'id': 'job-1'},
        uploadHeaders: {'content-location': '/api/v1/profile'},
        jobs: [
          {'id': 'job-1', 'status': 'succeeded'},
        ],
        onFetch: fetched.add,
      );

      await service.uploadGpx(_request());

      expect(fetched, ['/jobs/job-1']);
    });

    test('waits the Retry-After the server sends, within bounds', () async {
      final waits = <Duration>[];
      final service = _service(
        uploadBody: {'id': 'job-1'},
        uploadHeaders: {'retry-after': '3'},
        jobs: [
          {'id': 'job-1', 'status': 'running'},
          {'id': 'job-1', 'status': 'running'},
          {'id': 'job-1', 'status': 'succeeded'},
        ],
        jobRetryAfters: const [Duration(seconds: 60), null, null],
        waits: waits,
      );

      await service.uploadGpx(_request());

      expect(waits, const [
        Duration(seconds: 3),
        // 60 s is capped at the policy's maximum.
        Duration(seconds: 10),
        // No Retry-After: the default wait.
        Duration(seconds: 2),
      ]);
    });

    test('a 409 at the cap on open uploads is retried later', () async {
      final service = _service(
        uploadStatus: 409,
        uploadBody: {
          'type': 'urn:endurain:error:conflict',
          'detail': 'You already have 10 uploads in progress. Wait for one to finish, then upload again',
        },
        jobs: const [],
      );

      await expectLater(
        service.uploadGpx(_request()),
        throwsA(
          isA<AppException>().having(
            (e) => e.details,
            'details',
            ActivityUploadService.uploadLimitDetails,
          ),
        ),
      );
    });

    for (final (status, body, expected) in [
      (
        403,
        {'type': 'urn:endurain:error:mfa-enrolment-required'},
        ActivityUploadService.mfaEnrolmentRequiredDetails,
      ),
      (403, {'type': 'urn:endurain:error:permission-denied'}, 'HTTP 403'),
      (413, <String, Object?>{}, ActivityUploadService.fileTooLargeDetails),
      (
        415,
        <String, Object?>{},
        ActivityUploadService.unsupportedFileTypeDetails,
      ),
    ]) {
      test('a $status refusal reports $expected', () async {
        final service = _service(
          uploadStatus: status,
          uploadBody: body,
          jobs: const [],
        );

        await expectLater(
          service.uploadGpx(_request()),
          throwsA(
            isA<AppException>().having((e) => e.details, 'details', expected),
          ),
        );
      });
    }

    test('a 409 for a reused Idempotency-Key is a plain failure', () async {
      final service = _service(
        uploadStatus: 409,
        uploadBody: {
          'type': 'urn:endurain:error:conflict',
          'detail':
              'This Idempotency-Key was already used for a different request',
        },
        jobs: const [],
      );

      await expectLater(
        service.uploadGpx(_request()),
        throwsA(
          isA<AppException>().having((e) => e.details, 'details', 'HTTP 409'),
        ),
      );
    });
  });
}

ActivityUploadService _service({
  required Map<String, Object?> uploadBody,
  required List<Map<String, dynamic>> jobs,
  int uploadStatus = 202,
  Map<String, String> uploadHeaders = const {},
  List<Duration?> jobRetryAfters = const [],
  List<Duration>? waits,
  int maxPolls = 10,
  void Function(String endpoint)? onFetch,
  Future<Map<String, dynamic>> Function(String endpoint)? fetch,
}) {
  var poll = 0;
  return ActivityUploadService(
    config: ActivityUploadConfig(
      endpoint: '/upload',
      fieldName: 'file',
      ingestionJobPath: (id) => '/jobs/${Uri.encodeComponent(id)}',
    ),
    pollPolicy: IngestionPollPolicy(
      maxPolls: maxPolls,
      delay: (_, wait) async => waits?.add(wait),
    ),
    uploadFile:
        (_, _, _, {idempotencyKey, expectedOrigin, expectedProfileId}) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(uploadBody))),
            uploadStatus,
            headers: uploadHeaders,
          );
        },
    fetchIngestionJob: (endpoint, {expectedOrigin, expectedProfileId}) async {
      onFetch?.call(endpoint);
      if (fetch != null) {
        return (job: await fetch(endpoint), retryAfter: null);
      }
      final index = poll < jobs.length ? poll : jobs.length - 1;
      final retryAfter = poll < jobRetryAfters.length
          ? jobRetryAfters[poll]
          : null;
      poll++;
      return (job: jobs[index], retryAfter: retryAfter);
    },
  );
}

ActivityUploadRequest _request() {
  return const ActivityUploadRequest(filePath: '/tmp/activity.gpx');
}
