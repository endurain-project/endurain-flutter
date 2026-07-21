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

    testWidgets('throws a clear error when there is no scope', (tester) async {
      Object? caught;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            try {
              AppScope.servicesOf(context, listen: false);
            } catch (error) {
              caught = error;
            }
            return const SizedBox.shrink();
          },
        ),
      );

      expect(caught, isA<FlutterError>());
      expect('$caught', contains('AppScope'));
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
