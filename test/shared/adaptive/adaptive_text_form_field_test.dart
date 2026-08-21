import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    PlatformUtils.debugResetOverrides();
  });

  tearDown(() {
    PlatformUtils.debugResetOverrides();
  });

  testWidgets('Cupertino field aligns with expanded button width', (
    tester,
  ) async {
    PlatformUtils.debugIsApplePlatformOverride = true;

    await tester.pumpWidget(
      CupertinoApp(
        home: SizedBox(
          width: 390,
          height: 220,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AdaptiveTextFormField(
                label: 'Server URL',
                placeholder: 'https://example.com',
                prefixIcon: Icon(CupertinoIcons.globe),
              ),
              const SizedBox(height: 24),
              AdaptiveButton(label: 'Next', onPressed: () {}, expand: true),
            ],
          ),
        ),
      ),
    );

    final fieldRect = tester.getRect(find.byType(CupertinoTextFormFieldRow));
    final buttonRect = tester.getRect(find.byType(CupertinoButton));

    expect(fieldRect.left, buttonRect.left);
    expect(fieldRect.right, buttonRect.right);
  });

  testWidgets('renders Material TextFormField with mapped decoration', (
    tester,
  ) async {
    PlatformUtils.debugIsApplePlatformOverride = false;
    final controller = TextEditingController(text: 'abc');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveTextFormField(
            label: 'Email',
            placeholder: 'name@example.com',
            controller: controller,
            prefixIcon: const Icon(Icons.mail),
            suffix: const Icon(Icons.check),
          ),
        ),
      ),
    );

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('name@example.com'), findsOneWidget);
    expect(find.byIcon(Icons.mail), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('Material field invokes submit callback', (tester) async {
    PlatformUtils.debugIsApplePlatformOverride = false;
    String? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveTextFormField(
            label: 'Name',
            onFieldSubmitted: (value) => submitted = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Joao');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, 'Joao');
  });

  testWidgets('Cupertino field maps placeholder and obscureText', (
    tester,
  ) async {
    PlatformUtils.debugIsApplePlatformOverride = true;
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: AdaptiveTextFormField(
            label: 'Password',
            placeholder: 'Required',
            controller: controller,
            obscureText: true,
            prefixIcon: const Icon(CupertinoIcons.lock),
          ),
        ),
      ),
    );

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.obscureText, isTrue);
    expect(find.text('Required'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.lock), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
  });
}
