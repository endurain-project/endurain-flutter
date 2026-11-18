/// Builds the globally-unique identity of an authenticated connection.
///
/// A server-assigned account id (e.g. `"1"`) is only unique **within** a single
/// server. Endurain intentionally lets one app connect to a self-hosted
/// instance today and the managed ("Endurain Cloud") service in the future, and
/// the very same numeric account id can exist on both. Because health-platform
/// workout ids (HealthKit / Health Connect `sourceId`s) are device-global,
/// keying local provenance or per-connection scoping on the raw account id
/// would let data captured against one server collide with another.
///
/// [profileId] therefore combines the (already normalized) server origin with
/// the account id into one opaque, origin-qualified key. Every store that scopes
/// data to "the current connection" keys on this value, never the raw account
/// id, so two servers can never be confused for one another.
class ConnectionIdentity {
  const ConnectionIdentity._();

  /// Separator between the origin and the account id.
  ///
  /// `#` can never appear in a normalized origin (`ServerUrlResolver.normalize`
  /// rejects URLs with a fragment) nor in a numeric account id, so the composite
  /// is unambiguous. It is also plain enough to reproduce in SQL as
  /// `connection_origin || '#' || connection_profile_id`, which the activity
  /// store's migration relies on.
  static const String separator = '#';

  /// Returns the origin-qualified profile id for [accountId] on [origin].
  ///
  /// [origin] must already be normalized (see `ServerUrlResolver.normalize`).
  static String profileId({
    required String origin,
    required String accountId,
  }) => '$origin$separator$accountId';

  static final RegExp _legacyAccountId = RegExp(r'^[0-9]+$');

  /// Whether [accountId] is an integer id assigned by an Endurain server
  /// before v0.21, which switched every account id to a UUID.
  static bool isLegacyAccountId(String accountId) =>
      _legacyAccountId.hasMatch(accountId);

  /// Whether [profileId] is the profile id of a pre-v0.21 (integer) account on
  /// [origin], i.e. exactly `<origin>#<digits>`.
  static bool isLegacyProfileIdFor(String profileId, {required String origin}) {
    final prefix = '$origin$separator';
    return profileId.startsWith(prefix) &&
        isLegacyAccountId(profileId.substring(prefix.length));
  }
}
