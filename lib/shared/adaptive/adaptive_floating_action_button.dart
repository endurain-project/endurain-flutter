import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/utils/platform_utils.dart';

class AdaptiveFloatingActionButton extends StatelessWidget {
  const AdaptiveFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.materialIcon,
    required this.cupertinoIcon,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData materialIcon;
  final IconData cupertinoIcon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApplePlatform) {
      return SizedBox.square(
        dimension: LocationMarkerConstants.buttonSize,
        child: CupertinoButton.filled(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          child: Icon(cupertinoIcon, color: CupertinoColors.white, size: 28),
        ),
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(materialIcon),
    );
  }
}
