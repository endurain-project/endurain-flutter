import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:endurain/core/utils/platform_utils.dart';

Future<T?> adaptivePush<T>(BuildContext context, WidgetBuilder builder) {
  return Navigator.push<T>(
    context,
    PlatformUtils.isApplePlatform
        ? CupertinoPageRoute<T>(builder: builder)
        : MaterialPageRoute<T>(builder: builder),
  );
}
