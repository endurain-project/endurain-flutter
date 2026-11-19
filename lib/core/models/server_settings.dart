// Model representing server settings fetched from the server
import 'package:endurain/core/utils/json_parsing.dart';

class ServerSettings {
  const ServerSettings({
    required this.units,
    required this.publicShareableLinks,
    required this.publicShareableLinksUserInfo,
    required this.loginPhotoSet,
    required this.currency,
    required this.numRecordsPerPage,
    required this.signupEnabled,
    required this.ssoEnabled,
    required this.localLoginEnabled,
    required this.ssoAutoRedirect,
    this.tileserverUrl,
    this.tileserverAttribution,
    this.mapBackgroundColor,
    required this.passwordLengthRegularUsers,
    required this.passwordLengthAdminUsers,
    this.allowedRedirectUris,
  });

  final String units;
  final bool publicShareableLinks;
  final bool publicShareableLinksUserInfo;
  final bool loginPhotoSet;
  final String currency;
  final int numRecordsPerPage;
  final bool signupEnabled;
  final bool ssoEnabled;
  final bool localLoginEnabled;
  final bool ssoAutoRedirect;
  final String? tileserverUrl;
  final String? tileserverAttribution;
  final String? mapBackgroundColor;
  final int passwordLengthRegularUsers;
  final int passwordLengthAdminUsers;

  /// The exact addresses an SSO sign-in may return to (`ALLOWED_REDIRECT_URIS`),
  /// or `null` when the server does not publish them.
  final List<String>? allowedRedirectUris;

  factory ServerSettings.fromJson(Map<String, dynamic> json) {
    return ServerSettings(
      units: jsonString(json['units']) ?? 'metric',
      publicShareableLinks: jsonBool(json['public_shareable_links']) ?? false,
      publicShareableLinksUserInfo:
          jsonBool(json['public_shareable_links_user_info']) ?? false,
      loginPhotoSet: jsonBool(json['login_photo_set']) ?? false,
      currency: jsonString(json['currency']) ?? 'euro',
      numRecordsPerPage: jsonInt(json['num_records_per_page']) ?? 25,
      signupEnabled: jsonBool(json['signup_enabled']) ?? false,
      ssoEnabled: jsonBool(json['sso_enabled']) ?? false,
      localLoginEnabled: jsonBool(json['local_login_enabled']) ?? true,
      ssoAutoRedirect: jsonBool(json['sso_auto_redirect']) ?? false,
      tileserverUrl: jsonString(json['tileserver_url']),
      tileserverAttribution: jsonString(json['tileserver_attribution']),
      mapBackgroundColor: jsonString(json['map_background_color']),
      passwordLengthRegularUsers:
          jsonInt(json['password_length_regular_users']) ?? 8,
      passwordLengthAdminUsers:
          jsonInt(json['password_length_admin_users']) ?? 12,
      allowedRedirectUris: switch (json['allowed_redirect_uris']) {
        final List<Object?> uris => uris.whereType<String>().toList(),
        _ => null,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'units': units,
      'public_shareable_links': publicShareableLinks,
      'public_shareable_links_user_info': publicShareableLinksUserInfo,
      'login_photo_set': loginPhotoSet,
      'currency': currency,
      'num_records_per_page': numRecordsPerPage,
      'signup_enabled': signupEnabled,
      'sso_enabled': ssoEnabled,
      'local_login_enabled': localLoginEnabled,
      'sso_auto_redirect': ssoAutoRedirect,
      'tileserver_url': tileserverUrl,
      'tileserver_attribution': tileserverAttribution,
      'map_background_color': mapBackgroundColor,
      'password_length_regular_users': passwordLengthRegularUsers,
      'password_length_admin_users': passwordLengthAdminUsers,
      'allowed_redirect_uris': allowedRedirectUris,
    };
  }
}
