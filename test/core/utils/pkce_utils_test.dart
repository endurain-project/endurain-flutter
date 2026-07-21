import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/utils/pkce_utils.dart';

void main() {
  group('PkceUtils', () {
    test('generates verifier and challenge values for S256 flow', () {
      final pkce = PkceUtils.generatePkce();

      expect(pkce.verifier, isNotEmpty);
      expect(pkce.challenge, isNotEmpty);
      expect(pkce.verifier, isNot(equals(pkce.challenge)));
      expect(pkce.verifier.length, greaterThanOrEqualTo(43));
      expect(pkce.challenge.length, greaterThanOrEqualTo(43));
      expect(pkce.challenge, isNot(contains('=')));
      expect(pkce.challenge, isNot(contains('+')));
      expect(pkce.challenge, isNot(contains('/')));
    });
  });
}
