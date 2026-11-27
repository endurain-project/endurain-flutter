import 'package:endurain/features/activity/widgets/lazy_list_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  testWidgets('builds only the rows near the viewport', (tester) async {
    final built = <int>{};
    await tester.pumpWidget(
      TestMaterialApp(
        child: CustomScrollView(
          slivers: paddedSlivers(const EdgeInsets.all(16), [
            LazyListSection(
              header: 'Header',
              itemCount: 500,
              chunkSize: 10,
              itemBuilder: (context, index) {
                built.add(index);
                return SizedBox(height: 56, child: Text('row $index'));
              },
            ),
          ]),
        ),
      ),
    );

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('row 0'), findsOneWidget);
    expect(built.length, lessThan(100));
    expect(built, isNot(contains(499)));

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    for (var i = 0; i < 5; i++) {
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
    }
    expect(find.text('row 499'), findsOneWidget);
    expect(find.text('Header'), findsNothing);
  });
}
