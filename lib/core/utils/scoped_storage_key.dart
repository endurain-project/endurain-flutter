library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Builds a deterministic, collision-resistant storage key of the form
/// `<prefix>_<sha256hex(scope)>`.
///
/// Used to namespace persisted values (preferences, secure-storage entries,
/// local dedup identifiers) by a variable-length, potentially sensitive
/// [scope] such as a server origin or connection profile id. Hashing the scope
/// keeps the raw value out of the stored key while still yielding one stable
/// key per scope.
///
/// The output is stable across runs and platforms for the same inputs, so it is
/// safe to persist. Do not change the hash algorithm or format without a
/// migration: existing stored data is addressed by these keys.
String scopedStorageKey(String prefix, String scope) {
  final digest = sha256.convert(utf8.encode(scope)).toString();
  return '${prefix}_$digest';
}
