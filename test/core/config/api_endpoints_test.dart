import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiEndpoints', () {
    group('default /api/v1 base', () {
      const endpoints = ApiEndpoints();

      test('tokenEndpoint', () {
        expect(endpoints.tokenEndpoint, '/api/v1/auth/login');
      });

      test('mfaVerifyEndpoint', () {
        expect(endpoints.mfaVerifyEndpoint, '/api/v1/auth/mfa/verify');
      });

      test('refreshEndpoint', () {
        expect(endpoints.refreshEndpoint, '/api/v1/auth/refresh');
      });

      test('logoutEndpoint', () {
        expect(endpoints.logoutEndpoint, '/api/v1/auth/logout');
      });

      test('idpListEndpoint', () {
        expect(endpoints.idpListEndpoint, '/api/v1/public/idp');
      });

      test('idpLoginEndpoint', () {
        expect(endpoints.idpLoginEndpoint, '/api/v1/public/idp/login');
      });

      test('passwordChangeEndpoint', () {
        expect(
          endpoints.passwordChangeEndpoint,
          '/api/v1/auth/password-change',
        );
      });

      test('sessionTokensEndpoint encodes the session id', () {
        expect(
          endpoints.sessionTokensEndpoint('a b/1'),
          '/api/v1/auth/sessions/a%20b%2F1/tokens',
        );
      });

      test('idpIconEndpoint encodes the slug', () {
        expect(
          endpoints.idpIconEndpoint('my idp'),
          '/api/v1/public/idp/my%20idp/icon',
        );
      });

      test('serverSettingsEndpoint', () {
        expect(
          endpoints.serverSettingsEndpoint,
          '/api/v1/public/server-settings',
        );
      });

      test('activityUploadEndpoint', () {
        expect(endpoints.activityUploadEndpoint, '/api/v1/activities/upload');
      });

      test('activityIngestionJobEndpoint encodes the job id', () {
        expect(
          endpoints.activityIngestionJobEndpoint('a b/1'),
          '/api/v1/activities/ingestion-jobs/a%20b%2F1',
        );
      });
    });

    group('custom /api/v2 base', () {
      const v2 = ApiEndpoints(AppConfig(apiBasePath: '/api/v2'));

      test('tokenEndpoint uses v2 base', () {
        expect(v2.tokenEndpoint, '/api/v2/auth/login');
      });

      test('serverSettingsEndpoint uses v2 base', () {
        expect(v2.serverSettingsEndpoint, '/api/v2/public/server-settings');
      });

      test('activityUploadEndpoint uses v2 base', () {
        expect(v2.activityUploadEndpoint, '/api/v2/activities/upload');
      });
    });
  });
}
