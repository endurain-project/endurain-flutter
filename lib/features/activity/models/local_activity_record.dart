import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/copy_with.dart';
import 'package:endurain/core/utils/json_parsing.dart';
import 'package:endurain/features/activity/models/activity_type.dart';

enum LocalActivityUploadStatus {
  pending,
  uploaded,
  failed;

  static LocalActivityUploadStatus fromJson(Object? value) {
    return switch (value) {
      'pending' => LocalActivityUploadStatus.pending,
      'uploaded' => LocalActivityUploadStatus.uploaded,
      'failed' => LocalActivityUploadStatus.failed,
      _ => LocalActivityUploadStatus.failed,
    };
  }

  String toJson() => name;
}

class LocalActivityRecord {
  const LocalActivityRecord({
    required this.id,
    required this.activityType,
    required this.startedAt,
    required this.endedAt,
    required this.elapsedDurationSeconds,
    required this.distanceMeters,
    required this.pointCount,
    required this.gpxFileName,
    required this.uploadStatus,
    required this.createdAt,
    required this.updatedAt,
    this.averageSpeedMetersPerSecond,
    this.maxSpeedMetersPerSecond,
    this.elevationGainMeters,
    this.uploadedAt,
    this.lastUploadAttemptAt,
    this.lastUploadErrorCode,
    this.autoRetryEligible = true,
    this.gpxCleanupPending = false,
    this.idempotencyKey,
    this.connectionOrigin,
    this.connectionProfileId,
  });

  final String id;
  final ActivityType activityType;
  final DateTime startedAt;
  final DateTime endedAt;
  final int elapsedDurationSeconds;
  final double distanceMeters;
  final double? averageSpeedMetersPerSecond;
  final double? maxSpeedMetersPerSecond;
  final double? elevationGainMeters;
  final int pointCount;
  final String gpxFileName;
  final LocalActivityUploadStatus uploadStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? uploadedAt;
  final DateTime? lastUploadAttemptAt;
  final AppErrorCode? lastUploadErrorCode;

  /// Whether the durable queue may retry this record without user action.
  ///
  /// Network, timeout, and server 5xx failures remain eligible. Permanent
  /// request, authentication, configuration, and missing-file failures do not.
  final bool autoRetryEligible;

  /// The server accepted this activity, but removing its local GPX file still
  /// needs retrying because retention is disabled.
  final bool gpxCleanupPending;

  /// Stable key used for server-side upload de-duplication.
  ///
  /// `null` for GPS recordings, whose [id] is already a stable, persisted
  /// identity generated once at recording start. Health imports set this to a
  /// value derived from the source workout's UUID so that re-importing the same
  /// workout (e.g. after a reinstall that loses the local dedup table) collapses
  /// to the same server activity. Use [effectiveIdempotencyKey] when uploading.
  final String? idempotencyKey;

  /// Canonical origin selected when the activity was persisted.
  ///
  /// A `null` value means the activity was recorded in guest mode. It remains
  /// local until a future explicit assignment action chooses its destination.
  final String? connectionOrigin;
  final String? connectionProfileId;

  /// The key to send as the upload `Idempotency-Key`: the explicit
  /// [idempotencyKey] when set, otherwise the stable record [id].
  String get effectiveIdempotencyKey => idempotencyKey ?? id;

  LocalActivityRecord copyWith({
    String? id,
    ActivityType? activityType,
    DateTime? startedAt,
    DateTime? endedAt,
    int? elapsedDurationSeconds,
    double? distanceMeters,
    Object? averageSpeedMetersPerSecond = kUnset,
    Object? maxSpeedMetersPerSecond = kUnset,
    Object? elevationGainMeters = kUnset,
    int? pointCount,
    String? gpxFileName,
    LocalActivityUploadStatus? uploadStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? uploadedAt = kUnset,
    Object? lastUploadAttemptAt = kUnset,
    Object? lastUploadErrorCode = kUnset,
    bool? autoRetryEligible,
    bool? gpxCleanupPending,
    Object? idempotencyKey = kUnset,
    Object? connectionOrigin = kUnset,
    Object? connectionProfileId = kUnset,
  }) {
    return LocalActivityRecord(
      id: id ?? this.id,
      activityType: activityType ?? this.activityType,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      elapsedDurationSeconds:
          elapsedDurationSeconds ?? this.elapsedDurationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      averageSpeedMetersPerSecond:
          identical(averageSpeedMetersPerSecond, kUnset)
          ? this.averageSpeedMetersPerSecond
          : averageSpeedMetersPerSecond as double?,
      maxSpeedMetersPerSecond: identical(maxSpeedMetersPerSecond, kUnset)
          ? this.maxSpeedMetersPerSecond
          : maxSpeedMetersPerSecond as double?,
      elevationGainMeters: identical(elevationGainMeters, kUnset)
          ? this.elevationGainMeters
          : elevationGainMeters as double?,
      pointCount: pointCount ?? this.pointCount,
      gpxFileName: gpxFileName ?? this.gpxFileName,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uploadedAt: identical(uploadedAt, kUnset)
          ? this.uploadedAt
          : uploadedAt as DateTime?,
      lastUploadAttemptAt: identical(lastUploadAttemptAt, kUnset)
          ? this.lastUploadAttemptAt
          : lastUploadAttemptAt as DateTime?,
      lastUploadErrorCode: identical(lastUploadErrorCode, kUnset)
          ? this.lastUploadErrorCode
          : lastUploadErrorCode as AppErrorCode?,
      autoRetryEligible: autoRetryEligible ?? this.autoRetryEligible,
      gpxCleanupPending: gpxCleanupPending ?? this.gpxCleanupPending,
      idempotencyKey: identical(idempotencyKey, kUnset)
          ? this.idempotencyKey
          : idempotencyKey as String?,
      connectionOrigin: identical(connectionOrigin, kUnset)
          ? this.connectionOrigin
          : connectionOrigin as String?,
      connectionProfileId: identical(connectionProfileId, kUnset)
          ? this.connectionProfileId
          : connectionProfileId as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'activityType': activityType.apiValue,
      'startedAt': startedAt.toUtcIso8601(),
      'endedAt': endedAt.toUtcIso8601(),
      'elapsedDurationSeconds': elapsedDurationSeconds,
      'distanceMeters': distanceMeters,
      if (averageSpeedMetersPerSecond != null)
        'averageSpeedMetersPerSecond': averageSpeedMetersPerSecond,
      if (maxSpeedMetersPerSecond != null)
        'maxSpeedMetersPerSecond': maxSpeedMetersPerSecond,
      if (elevationGainMeters != null)
        'elevationGainMeters': elevationGainMeters,
      'pointCount': pointCount,
      'gpxFileName': gpxFileName,
      'uploadStatus': uploadStatus.toJson(),
      'createdAt': createdAt.toUtcIso8601(),
      'updatedAt': updatedAt.toUtcIso8601(),
      if (uploadedAt != null) 'uploadedAt': uploadedAt!.toUtcIso8601(),
      if (lastUploadAttemptAt != null)
        'lastUploadAttemptAt': lastUploadAttemptAt!.toUtcIso8601(),
      if (lastUploadErrorCode != null)
        'lastUploadErrorCode': lastUploadErrorCode!.name,
      'autoRetryEligible': autoRetryEligible,
      'gpxCleanupPending': gpxCleanupPending,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      if (connectionOrigin != null) 'connectionOrigin': connectionOrigin,
      if (connectionProfileId != null)
        'connectionProfileId': connectionProfileId,
    };
  }

  factory LocalActivityRecord.fromJson(Map<dynamic, dynamic> json) {
    final id = jsonRequiredString(json['id'], 'id');
    final startedAt = jsonRequiredDateTime(json['startedAt'], 'startedAt');
    final endedAt = jsonRequiredDateTime(json['endedAt'], 'endedAt');
    final createdAt = jsonRequiredDateTime(json['createdAt'], 'createdAt');
    final updatedAt = jsonRequiredDateTime(json['updatedAt'], 'updatedAt');

    return LocalActivityRecord(
      id: id,
      activityType: ActivityType.fromApiValue(jsonString(json['activityType'])),
      startedAt: startedAt,
      endedAt: endedAt,
      elapsedDurationSeconds: jsonInt(json['elapsedDurationSeconds']) ?? 0,
      distanceMeters: jsonDouble(json['distanceMeters']) ?? 0,
      averageSpeedMetersPerSecond: jsonDouble(
        json['averageSpeedMetersPerSecond'],
      ),
      maxSpeedMetersPerSecond: jsonDouble(json['maxSpeedMetersPerSecond']),
      elevationGainMeters: jsonDouble(json['elevationGainMeters']),
      pointCount: jsonInt(json['pointCount']) ?? 0,
      gpxFileName: jsonRequiredString(json['gpxFileName'], 'gpxFileName'),
      uploadStatus: LocalActivityUploadStatus.fromJson(json['uploadStatus']),
      createdAt: createdAt,
      updatedAt: updatedAt,
      uploadedAt: jsonDateTime(json['uploadedAt']),
      lastUploadAttemptAt: jsonDateTime(json['lastUploadAttemptAt']),
      lastUploadErrorCode: appErrorCodeByName(json['lastUploadErrorCode']),
      autoRetryEligible: json['autoRetryEligible'] is bool
          ? json['autoRetryEligible'] as bool
          : true,
      gpxCleanupPending: json['gpxCleanupPending'] is bool
          ? json['gpxCleanupPending'] as bool
          : false,
      idempotencyKey: jsonString(json['idempotencyKey']),
      connectionOrigin: jsonString(json['connectionOrigin']),
      connectionProfileId: jsonString(json['connectionProfileId']),
    );
  }
}
