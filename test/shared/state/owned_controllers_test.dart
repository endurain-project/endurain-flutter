import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

class _SpyController extends ChangeNotifier {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

class _HostWidget extends StatefulWidget {
  const _HostWidget({this.injected, required this.onChanged});

  final _SpyController? injected;
  final VoidCallback onChanged;

  @override
  State<_HostWidget> createState() => _HostWidgetState();
}

class _HostWidgetState extends State<_HostWidget> with OwnedControllers {
  late final _SpyController controller;
  late final bool wasCreatedLocally;

  @override
  void initState() {
    super.initState();
    wasCreatedLocally = widget.injected == null;
    controller = registerController(
      widget.injected,
      _SpyController.new,
      onChanged: widget.onChanged,
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ObserveHostWidget extends StatefulWidget {
  const _ObserveHostWidget({required this.observed, required this.onChanged});

  final _SpyController observed;
  final VoidCallback onChanged;

  @override
  State<_ObserveHostWidget> createState() => _ObserveHostWidgetState();
}

class _ObserveHostWidgetState extends State<_ObserveHostWidget>
    with OwnedControllers {
  late final _SpyController controller;

  @override
  void initState() {
    super.initState();
    controller = observeController(
      widget.observed,
      onChanged: widget.onChanged,
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  group('OwnedControllers', () {
    testWidgets('disposes controllers it creates locally', (tester) async {
      _SpyController? created;
      await tester.pumpWidget(_HostWidget(onChanged: () {}));
      final state = tester.state<_HostWidgetState>(find.byType(_HostWidget));
      created = state.controller;
      expect(state.wasCreatedLocally, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(created.disposed, isTrue);
    });

    testWidgets('does not dispose injected controllers', (tester) async {
      final injected = _SpyController();
      addTearDown(injected.dispose);

      await tester.pumpWidget(
        _HostWidget(injected: injected, onChanged: () {}),
      );

      await tester.pumpWidget(const SizedBox.shrink());

      expect(injected.disposed, isFalse);
    });

    testWidgets('attaches and detaches the onChanged listener', (tester) async {
      final injected = _SpyController();
      addTearDown(injected.dispose);
      var calls = 0;

      await tester.pumpWidget(
        _HostWidget(injected: injected, onChanged: () => calls++),
      );

      injected.notifyListeners();
      expect(calls, 1);

      await tester.pumpWidget(const SizedBox.shrink());

      // Listener was removed on dispose; the injected controller survives and
      // further notifications no longer reach the detached listener.
      injected.notifyListeners();
      expect(calls, 1);
    });

    testWidgets('observeController never disposes the observed controller', (
      tester,
    ) async {
      final observed = _SpyController();
      addTearDown(observed.dispose);

      await tester.pumpWidget(
        _ObserveHostWidget(observed: observed, onChanged: () {}),
      );

      await tester.pumpWidget(const SizedBox.shrink());

      expect(observed.disposed, isFalse);
    });

    testWidgets('observeController detaches its listener on dispose', (
      tester,
    ) async {
      final observed = _SpyController();
      addTearDown(observed.dispose);
      var calls = 0;

      await tester.pumpWidget(
        _ObserveHostWidget(observed: observed, onChanged: () => calls++),
      );

      observed.notifyListeners();
      expect(calls, 1);

      await tester.pumpWidget(const SizedBox.shrink());

      observed.notifyListeners();
      expect(calls, 1);
    });
  });
}
