import 'dart:async';

import 'package:endurain/core/services/platform/app_links_service.dart';

class FakeAppLinksService implements AppLinksService {
  final _controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get uriLinkStream => _controller.stream;

  void add(Uri uri) {
    _controller.add(uri);
  }

  void addError(Object error) {
    _controller.addError(error);
  }

  Future<void> close() {
    return _controller.close();
  }
}

class EmptyAppLinksService implements AppLinksService {
  const EmptyAppLinksService();

  @override
  Stream<Uri> get uriLinkStream => const Stream<Uri>.empty();
}
