import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ActivityUploadService ingestion job polling', () {
    test('polls the job after a 202 until it completes', () async {
      final fetched = <String>[];
      final service = _service(
        uploadBody: {'id': 'job 1', 'status': 'pending'},
        jobs: [
          {'id': 'job 1', 'status': 'pending', 'completed_at': null},
          {'id': 'job 1', 'status': 'processing', 'completed_at': null},
          {
            'id': 'job 1',
            'status': 'completed',
            'completed_at': '2026-10-19T21:14:33Z',
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
            'completed_at': '2026-10-19T21:14:33Z',
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
            'completed_at': '2026-10-19T21:14:33Z',
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

    test('fails when files failed even if completed', () async {
      final service = _service(
        uploadBody: {'id': 'job-1'},
        jobs: [
          {
            'id': 'job-1',
            'status': 'completed',
            'completed_at': '2026-10-19T21:14:33Z',
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
          {'id': 'job-1', 'status': 'pending', 'completed_at': null},
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
            'status': 'completed',
            'completed_at': '2026-10-19T21:14:33Z',
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
  });
}

ActivityUploadService _service({
  required Map<String, Object?> uploadBody,
  required List<Map<String, dynamic>> jobs,
  int uploadStatus = 202,
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
    pollPolicy: IngestionPollPolicy(maxPolls: maxPolls, delay: (_) async {}),
    uploadFile:
        (_, _, _, {idempotencyKey, expectedOrigin, expectedProfileId}) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(uploadBody))),
            uploadStatus,
          );
        },
    fetchIngestionJob: (endpoint, {expectedOrigin, expectedProfileId}) async {
      onFetch?.call(endpoint);
      if (fetch != null) {
        return fetch(endpoint);
      }
      final index = poll < jobs.length ? poll : jobs.length - 1;
      poll++;
      return jobs[index];
    },
  );
}

ActivityUploadRequest _request() {
  return const ActivityUploadRequest(
    filePath: '/tmp/activity.gpx',
    activityType: ActivityType.run,
  );
}
