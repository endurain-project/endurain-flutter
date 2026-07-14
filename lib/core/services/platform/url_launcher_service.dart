import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  const UrlLauncherService();

  Future<bool> launchExternalApplication(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
