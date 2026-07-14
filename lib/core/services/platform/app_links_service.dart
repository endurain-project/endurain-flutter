import 'package:app_links/app_links.dart';

abstract class AppLinksService {
  Stream<Uri> get uriLinkStream;
}

class DefaultAppLinksService implements AppLinksService {
  DefaultAppLinksService({AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Stream<Uri> get uriLinkStream => _appLinks.uriLinkStream;
}
