import 'package:endurain/core/utils/connection_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectionIdentity.profileId', () {
    test('combines origin and account id with the separator', () {
      expect(
        ConnectionIdentity.profileId(
          origin: 'https://a.example',
          accountId: '1',
        ),
        'https://a.example#1',
      );
    });

    test('is stable for the same origin and account id', () {
      final first = ConnectionIdentity.profileId(
        origin: 'https://a.example',
        accountId: '1',
      );
      final second = ConnectionIdentity.profileId(
        origin: 'https://a.example',
        accountId: '1',
      );
      expect(first, second);
    });

    test('is distinct across origins that share an account id', () {
      // The core cross-instance safety property: account id "1" on a
      // self-hosted instance and on the managed service must never collide.
      final selfHosted = ConnectionIdentity.profileId(
        origin: 'https://home.example',
        accountId: '1',
      );
      final managed = ConnectionIdentity.profileId(
        origin: 'https://app.endurain.example',
        accountId: '1',
      );
      expect(selfHosted, isNot(managed));
    });

    test('is distinct across account ids on the same origin', () {
      final first = ConnectionIdentity.profileId(
        origin: 'https://a.example',
        accountId: '1',
      );
      final second = ConnectionIdentity.profileId(
        origin: 'https://a.example',
        accountId: '2',
      );
      expect(first, isNot(second));
    });
  });

  group('ConnectionIdentity legacy ids', () {
    test('an integer account id is a legacy one, a UUID is not', () {
      expect(ConnectionIdentity.isLegacyAccountId('42'), isTrue);
      expect(
        ConnectionIdentity.isLegacyAccountId(
          '7c9e6679-7425-40de-944b-e07fc1f90ae7',
        ),
        isFalse,
      );
      expect(ConnectionIdentity.isLegacyAccountId(''), isFalse);
      expect(ConnectionIdentity.isLegacyAccountId('-1'), isFalse);
    });

    test('a legacy profile id must belong to the given origin', () {
      const origin = 'https://a.example';
      expect(
        ConnectionIdentity.isLegacyProfileIdFor(
          'https://a.example#42',
          origin: origin,
        ),
        isTrue,
      );
      expect(
        ConnectionIdentity.isLegacyProfileIdFor(
          'https://b.example#42',
          origin: origin,
        ),
        isFalse,
      );
      expect(
        ConnectionIdentity.isLegacyProfileIdFor(
          'https://a.example#7c9e6679-7425-40de-944b-e07fc1f90ae7',
          origin: origin,
        ),
        isFalse,
      );
      // A pre-origin-qualified raw id is not matched.
      expect(
        ConnectionIdentity.isLegacyProfileIdFor('42', origin: origin),
        isFalse,
      );
    });
  });
}
