import 'package:endurain/features/health/models/health_workout_changes.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';

/// Reads which workouts were added or changed since a change token, so an
/// automatic import reads only those instead of a whole time window.
abstract interface class HealthWorkoutChangesReader {
  /// Returns a token for the workout changes made from now on.
  Future<String> currentToken();

  /// Returns the workout changes made since [token].
  Future<HealthWorkoutChanges> changesSince(String token);
}

/// Health Connect implementation backed by the `health` plugin's changes
/// token API. A workout route is part of its exercise session record, so a
/// route added later shows up as a changed workout.
class HealthConnectWorkoutChangesReader implements HealthWorkoutChangesReader {
  const HealthConnectWorkoutChangesReader(this._health);

  final Health _health;

  static const _types = [HealthDataType.WORKOUT];

  @override
  Future<String> currentToken() async {
    final token = await _health.getChangesToken(types: _types);
    if (token == null || token.isEmpty) {
      throw StateError('Health Connect returned no changes token');
    }
    return token;
  }

  @override
  Future<HealthWorkoutChanges> changesSince(String token) async {
    var next = token;
    DateTime? earliest;
    while (true) {
      final page = await _health.getChanges(changesToken: next);
      if (page == null) {
        throw StateError('Health Connect returned no changes');
      }
      if (page.changesTokenExpired) return const HealthWorkoutChanges.expired();
      for (final point in page.upsertedDataPoints) {
        if (point.type != HealthDataType.WORKOUT) continue;
        final start = point.dateFrom.toUtc();
        if (earliest == null || start.isBefore(earliest)) earliest = start;
      }
      next = page.nextChangesToken;
      if (!page.hasMore) {
        return HealthWorkoutChanges(nextToken: next, earliestStart: earliest);
      }
    }
  }
}

/// HealthKit implementation backed by anchored queries over workouts and
/// workout routes (`ios/Runner/Health/HealthWorkoutChangesChannel.swift`).
/// The token is the encoded pair of query anchors.
class MethodChannelHealthWorkoutChangesReader
    implements HealthWorkoutChangesReader {
  const MethodChannelHealthWorkoutChangesReader({
    MethodChannel channel = const MethodChannel(_channelName),
  }) : _channel = channel;

  static const String _channelName = 'endurain/health_workout_changes';
  static const String _currentTokenMethod = 'currentToken';
  static const String _changesSinceMethod = 'changesSince';

  final MethodChannel _channel;

  @override
  Future<String> currentToken() async {
    final token = await _channel.invokeMethod<String>(_currentTokenMethod);
    if (token == null || token.isEmpty) {
      throw const FormatException('Expected a HealthKit changes token');
    }
    return token;
  }

  @override
  Future<HealthWorkoutChanges> changesSince(String token) async {
    final raw = await _channel.invokeMethod<Object?>(_changesSinceMethod, {
      'token': token,
    });
    return decodeHealthWorkoutChanges(raw);
  }
}

/// Decodes the channel's `{nextToken, earliestStartMs}` reply; a `null`
/// `nextToken` means the token was not readable, which is treated as expired.
///
/// Throws [FormatException] for anything else, so a malformed reply fails the
/// pass rather than skipping changes.
HealthWorkoutChanges decodeHealthWorkoutChanges(Object? raw) {
  if (raw is! Map) {
    throw const FormatException('Expected a HealthKit changes map');
  }
  final nextToken = raw['nextToken'];
  final earliestStartMs = raw['earliestStartMs'];
  if (nextToken == null) return const HealthWorkoutChanges.expired();
  if (nextToken is! String || nextToken.isEmpty) {
    throw const FormatException('nextToken must be a non-empty string');
  }
  if (earliestStartMs != null && earliestStartMs is! num) {
    throw const FormatException('earliestStartMs must be a number');
  }
  return HealthWorkoutChanges(
    nextToken: nextToken,
    earliestStart: earliestStartMs is num
        ? DateTime.fromMillisecondsSinceEpoch(
            earliestStartMs.round(),
            isUtc: true,
          )
        : null,
  );
}
