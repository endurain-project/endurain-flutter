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
    required this.passwordType,
    required this.passwordLengthRegularUsers,
    required this.passwordLengthAdminUsers,
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
  final String passwordType;
  final int passwordLengthRegularUsers;
  final int passwordLengthAdminUsers;

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
      passwordType: jsonString(json['password_type']) ?? 'strict',
      passwordLengthRegularUsers:
          jsonInt(json['password_length_regular_users']) ?? 8,
      passwordLengthAdminUsers:
          jsonInt(json['password_length_admin_users']) ?? 12,
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
      'password_type': passwordType,
      'password_length_regular_users': passwordLengthRegularUsers,
      'password_length_admin_users': passwordLengthAdminUsers,
    };
  }
}
