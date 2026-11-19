import 'package:endurain/core/models/identity_provider.dart';
import 'package:endurain/core/models/server_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IdentityProvider', () {
    test('parses and serializes JSON', () {
      final provider = IdentityProvider.fromJson({
        'id': '0c0f8e0e-3f0b-4a50-9a58-6a1d0a2d5d11',
        'slug': 'keycloak',
        'name': 'Keycloak',
        'icon': 'keycloak',
        'icon_uploaded': true,
      });

      expect(provider.id, '0c0f8e0e-3f0b-4a50-9a58-6a1d0a2d5d11');
      expect(provider.slug, 'keycloak');
      expect(provider.name, 'Keycloak');
      expect(provider.icon, 'keycloak');
      expect(provider.iconUploaded, isTrue);
      expect(provider.toJson(), {
        'id': '0c0f8e0e-3f0b-4a50-9a58-6a1d0a2d5d11',
        'slug': 'keycloak',
        'name': 'Keycloak',
        'icon': 'keycloak',
        'icon_uploaded': true,
      });
    });

    test('accepts an integer id from an older server as text', () {
      final provider = IdentityProvider.fromJson({
        'id': 1,
        'slug': 'keycloak',
        'name': 'Keycloak',
      });

      expect(provider.id, '1');
      expect(provider.iconUploaded, isFalse);
    });
  });

  group('ServerSettings', () {
    test('uses safe defaults for missing optional server fields', () {
      final settings = ServerSettings.fromJson(<String, dynamic>{});

      expect(settings.units, 'metric');
      expect(settings.currency, 'euro');
      expect(settings.numRecordsPerPage, 25);
      expect(settings.localLoginEnabled, isTrue);
      expect(settings.ssoEnabled, isFalse);
      expect(settings.ssoAutoRedirect, isFalse);
      expect(settings.allowedRedirectUris, isNull);
      expect(settings.passwordLengthRegularUsers, 8);
      expect(settings.passwordLengthAdminUsers, 12);
    });

    test('round-trips configured map and auth settings', () {
      final settings = ServerSettings.fromJson({
        'units': 'imperial',
        'public_shareable_links': true,
        'public_shareable_links_user_info': true,
        'login_photo_set': true,
        'currency': 'usd',
        'num_records_per_page': 50,
        'signup_enabled': true,
        'sso_enabled': true,
        'local_login_enabled': false,
        'sso_auto_redirect': true,
        'tileserver_url': 'https://tiles.example.test/{z}/{x}/{y}.png',
        'tileserver_attribution': 'Tiles Example',
        'map_background_color': '#ffffff',
        'password_length_regular_users': 10,
        'password_length_admin_users': 16,
        'allowed_redirect_uris': ['com.endurain.endurain:/auth/sso/callback'],
      });

      expect(settings.toJson(), {
        'units': 'imperial',
        'public_shareable_links': true,
        'public_shareable_links_user_info': true,
        'login_photo_set': true,
        'currency': 'usd',
        'num_records_per_page': 50,
        'signup_enabled': true,
        'sso_enabled': true,
        'local_login_enabled': false,
        'sso_auto_redirect': true,
        'tileserver_url': 'https://tiles.example.test/{z}/{x}/{y}.png',
        'tileserver_attribution': 'Tiles Example',
        'map_background_color': '#ffffff',
        'password_length_regular_users': 10,
        'password_length_admin_users': 16,
        'allowed_redirect_uris': ['com.endurain.endurain:/auth/sso/callback'],
      });
    });
  });
}
