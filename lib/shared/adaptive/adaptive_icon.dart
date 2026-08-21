import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:endurain/core/utils/platform_utils.dart';

class AdaptiveIcon extends StatelessWidget {
  const AdaptiveIcon({
    super.key,
    required this.materialIcon,
    required this.cupertinoIcon,
    this.color,
    this.size,
  });

  final IconData materialIcon;
  final IconData cupertinoIcon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      PlatformUtils.isApplePlatform ? cupertinoIcon : materialIcon,
      color: color,
      size: size,
    );
  }
}
