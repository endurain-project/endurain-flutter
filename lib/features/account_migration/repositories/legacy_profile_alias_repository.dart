import 'dart:convert';

import 'package:endurain/core/services/app_preferences_store.dart';

/// What the app remembers about the pre-v0.21 profile ids on this device.
///
/// Endurain v0.21 changed every account id from an integer to a UUID, so the
/// same account gets a new connection profile id (`<origin>#<uuid>` instead of
/// `<origin>#42`). The server offers no mapping between the two, so the app
/// records:
/// - [hints]: legacy profile ids read from the session stored before the
///   upgrade, with a hash of the username that signed in, so a later sign-in
///   by the same username can be matched without asking;
/// - [adopted]: legacy profile id → the new profile id its data was moved to;
/// - [declined]: legacy profile id → the new profile ids whose user said the
///   data was not theirs.
class LegacyProfileAliases {
  const LegacyProfileAliases({
    this.hints = const {},
    this.adopted = const {},
    this.declined = const {},
  });

  /// Legacy profile id → SHA-256 of the lower-cased username, or `null` when
  /// the stored session had no username (an SSO sign-in).
  final Map<String, String?> hints;
  final Map<String, String> adopted;
  final Map<String, Set<String>> declined;

  LegacyProfileAliases copyWith({
    Map<String, String?>? hints,
    Map<String, String>? adopted,
    Map<String, Set<String>>? declined,
  }) {
    return LegacyProfileAliases(
      hints: hints ?? this.hints,
      adopted: adopted ?? this.adopted,
      declined: declined ?? this.declined,
    );
  }

  Map<String, Object?> toJson() => {
    'hints': hints,
    'adopted': adopted,
    'declined': {
      for (final entry in declined.entries) entry.key: entry.value.toList(),
    },
  };

  /// Parses stored JSON, dropping any member that does not have the expected
  /// shape rather than failing, so a damaged value never blocks sign-in.
  factory LegacyProfileAliases.fromJson(Object? json) {
    if (json is! Map<Object?, Object?>) {
      return const LegacyProfileAliases();
    }
    final hints = <String, String?>{};
    if (json['hints'] case final Map<Object?, Object?> raw) {
      for (final MapEntry(:key, :value) in raw.entries) {
        if (key is String && (value == null || value is String)) {
          hints[key] = value as String?;
        }
      }
    }
    final adopted = <String, String>{};
    if (json['adopted'] case final Map<Object?, Object?> raw) {
      for (final MapEntry(:key, :value) in raw.entries) {
        if (key is String && value is String) {
          adopted[key] = value;
        }
      }
    }
    final declined = <String, Set<String>>{};
    if (json['declined'] case final Map<Object?, Object?> raw) {
      for (final MapEntry(:key, :value) in raw.entries) {
        if (key is String && value is List<Object?>) {
          declined[key] = value.whereType<String>().toSet();
        }
      }
    }
    return LegacyProfileAliases(
      hints: hints,
      adopted: adopted,
      declined: declined,
    );
  }
}

/// Persists [LegacyProfileAliases] as one JSON value in [AppPreferencesStore].
///
/// The value holds profile ids (server origin plus account id) and a username
/// hash, never a username or a credential, so it does not need the keychain.
class LegacyProfileAliasRepository {
  const LegacyProfileAliasRepository({required AppPreferencesStore preferences})
    : _preferences = preferences;

  static const String _key = 'endurain.legacy_profile_aliases.v1';

  final AppPreferencesStore _preferences;

  Future<LegacyProfileAliases> load() async {
    final raw = await _preferences.read(key: _key);
    if (raw == null) {
      return const LegacyProfileAliases();
    }
    try {
      return LegacyProfileAliases.fromJson(jsonDecode(raw));
    } on FormatException {
      return const LegacyProfileAliases();
    }
  }

  Future<void> save(LegacyProfileAliases aliases) {
    return _preferences.write(key: _key, value: jsonEncode(aliases.toJson()));
  }
}
