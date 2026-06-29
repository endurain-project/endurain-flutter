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
    this.uploadedAt,
    this.lastUploadAttemptAt,
    this.lastUploadErrorCode,
    this.serverActivityId,
  });

  final String id;
  final ActivityType activityType;
  final DateTime startedAt;
  final DateTime endedAt;
  final int elapsedDurationSeconds;
  final double distanceMeters;
  final double? averageSpeedMetersPerSecond;
  final int pointCount;
  final String gpxFileName;
  final LocalActivityUploadStatus uploadStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? uploadedAt;
  final DateTime? lastUploadAttemptAt;
  final AppErrorCode? lastUploadErrorCode;
  final String? serverActivityId;

  LocalActivityRecord copyWith({
    String? id,
    ActivityType? activityType,
    DateTime? startedAt,
    DateTime? endedAt,
    int? elapsedDurationSeconds,
    double? distanceMeters,
    Object? averageSpeedMetersPerSecond = kUnset,
    int? pointCount,
    String? gpxFileName,
    LocalActivityUploadStatus? uploadStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? uploadedAt = kUnset,
    Object? lastUploadAttemptAt = kUnset,
    Object? lastUploadErrorCode = kUnset,
    Object? serverActivityId = kUnset,
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
      serverActivityId: identical(serverActivityId, kUnset)
          ? this.serverActivityId
          : serverActivityId as String?,
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
      if (serverActivityId != null) 'serverActivityId': serverActivityId,
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
      pointCount: jsonInt(json['pointCount']) ?? 0,
      gpxFileName: jsonRequiredString(json['gpxFileName'], 'gpxFileName'),
      uploadStatus: LocalActivityUploadStatus.fromJson(json['uploadStatus']),
      createdAt: createdAt,
      updatedAt: updatedAt,
      uploadedAt: jsonDateTime(json['uploadedAt']),
      lastUploadAttemptAt: jsonDateTime(json['lastUploadAttemptAt']),
      lastUploadErrorCode: appErrorCodeByName(json['lastUploadErrorCode']),
      serverActivityId: jsonString(json['serverActivityId']),
    );
  }
}
