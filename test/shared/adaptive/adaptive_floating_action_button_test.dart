import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/shared/adaptive/adaptive_floating_action_button.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveFloatingActionButton', () {
    tearDown(PlatformUtils.debugResetOverrides);

    testWidgets('uses the map floating control size on Apple platforms', (
      tester,
    ) async {
      PlatformUtils.debugIsApplePlatformOverride = true;

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: AdaptiveFloatingActionButton(
              onPressed: () {},
              materialIcon: Icons.my_location,
              cupertinoIcon: CupertinoIcons.location_solid,
            ),
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(CupertinoButton));

      expect(buttonSize.width, LocationMarkerConstants.buttonSize);
      expect(buttonSize.height, LocationMarkerConstants.buttonSize);
    });
  });
}
