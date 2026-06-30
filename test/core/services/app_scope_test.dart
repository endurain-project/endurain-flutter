import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/services/app_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('AppScope.servicesOf', () {
    testWidgets('returns the scoped services when listening (default)', (
      tester,
    ) async {
      final services = AppServices();
      late final AppServices resolved;

      await tester.pumpWidget(
        AppScope(
          services: services,
          child: Builder(
            builder: (context) {
              resolved = AppScope.servicesOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(identical(resolved, services), isTrue);
    });

    testWidgets('returns the scoped services when not listening', (
      tester,
    ) async {
      final services = AppServices();
      late final AppServices resolved;

      await tester.pumpWidget(
        AppScope(
          services: services,
          child: Builder(
            builder: (context) {
              resolved = AppScope.servicesOf(context, listen: false);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(identical(resolved, services), isTrue);
    });

    testWidgets('falls back to AppServices.instance without a scope', (
      tester,
    ) async {
      late final AppServices resolved;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            resolved = AppScope.servicesOf(context, listen: false);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(identical(resolved, AppServices.instance), isTrue);
    });
  });

  group('AppScope.updateShouldNotify', () {
    test('notifies only when the services instance changes', () {
      final servicesA = AppServices();
      final servicesB = AppServices();

      final scope = AppScope(services: servicesA, child: const SizedBox());

      expect(
        scope.updateShouldNotify(
          AppScope(services: servicesB, child: const SizedBox()),
        ),
        isTrue,
      );
      expect(
        scope.updateShouldNotify(
          AppScope(services: servicesA, child: const SizedBox()),
        ),
        isFalse,
      );
    });
  });
}
