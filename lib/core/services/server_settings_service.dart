import 'package:http/http.dart' as http;
import 'package:endurain/core/models/server_settings.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/base_http_client.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';

/// Service for fetching and managing server settings
class ServerSettingsService {
  ServerSettingsService({
    SecureStorageService? storage,
    ServerUrlResolver? urlResolver,
    BaseHttpClient? baseClient,
    http.Client? httpClient,
  }) : _storage = storage ?? SecureStorageService(),
       _urlResolver =
           urlResolver ??
           ServerUrlResolver(storage: storage ?? SecureStorageService()),
       _http = baseClient ?? BaseHttpClient(httpClient: httpClient);

  final SecureStorageService _storage;
  final ServerUrlResolver _urlResolver;
  final BaseHttpClient _http;

  /// Fetch server settings from the server
  Future<ServerSettings> getServerSettings({String? serverUrl}) async {
    final url = await _urlResolver.resolve(serverUrl: serverUrl);
    final apiUrl = Uri.parse('$url${ApiConstants.serverSettingsEndpoint}');

    try {
      final data = await _http.getJsonObject(
        apiUrl,
        failureCode: AppErrorCode.fetchServerSettingsFailed,
      );
      final settings = ServerSettings.fromJson(data);

      // Store tile server settings for later use
      if (settings.tileserverUrl != null &&
          settings.tileserverUrl!.isNotEmpty) {
        await _storage.setTileServerUrl(settings.tileserverUrl!);
      }
      if (settings.tileserverAttribution != null &&
          settings.tileserverAttribution!.isNotEmpty) {
        await _storage.setTileServerAttribution(
          settings.tileserverAttribution!,
        );
      }
      if (settings.mapBackgroundColor != null &&
          settings.mapBackgroundColor!.isNotEmpty) {
        await _storage.setMapBackgroundColor(settings.mapBackgroundColor!);
      }

      return settings;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(AppErrorCode.fetchServerSettingsFailed, cause: e);
    }
  }
}
