import 'package:endurain/core/models/app_exception.dart';
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
    Object? averageSpeedMetersPerSecond = _unset,
    int? pointCount,
    String? gpxFileName,
    LocalActivityUploadStatus? uploadStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? uploadedAt = _unset,
    Object? lastUploadAttemptAt = _unset,
    Object? lastUploadErrorCode = _unset,
    Object? serverActivityId = _unset,
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
          identical(averageSpeedMetersPerSecond, _unset)
          ? this.averageSpeedMetersPerSecond
          : averageSpeedMetersPerSecond as double?,
      pointCount: pointCount ?? this.pointCount,
      gpxFileName: gpxFileName ?? this.gpxFileName,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uploadedAt: identical(uploadedAt, _unset)
          ? this.uploadedAt
          : uploadedAt as DateTime?,
      lastUploadAttemptAt: identical(lastUploadAttemptAt, _unset)
          ? this.lastUploadAttemptAt
          : lastUploadAttemptAt as DateTime?,
      lastUploadErrorCode: identical(lastUploadErrorCode, _unset)
          ? this.lastUploadErrorCode
          : lastUploadErrorCode as AppErrorCode?,
      serverActivityId: identical(serverActivityId, _unset)
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
    final id = _requiredString(json['id'], 'id');
    final startedAt = _requiredDateTime(json['startedAt'], 'startedAt');
    final endedAt = _requiredDateTime(json['endedAt'], 'endedAt');
    final createdAt = _requiredDateTime(json['createdAt'], 'createdAt');
    final updatedAt = _requiredDateTime(json['updatedAt'], 'updatedAt');

    return LocalActivityRecord(
      id: id,
      activityType: ActivityType.fromApiValue(
        jsonString(json['activityType']),
      ),
      startedAt: startedAt,
      endedAt: endedAt,
      elapsedDurationSeconds: jsonInt(json['elapsedDurationSeconds']) ?? 0,
      distanceMeters: jsonDouble(json['distanceMeters']) ?? 0,
      averageSpeedMetersPerSecond: jsonDouble(
        json['averageSpeedMetersPerSecond'],
      ),
      pointCount: jsonInt(json['pointCount']) ?? 0,
      gpxFileName: _requiredString(json['gpxFileName'], 'gpxFileName'),
      uploadStatus: LocalActivityUploadStatus.fromJson(json['uploadStatus']),
      createdAt: createdAt,
      updatedAt: updatedAt,
      uploadedAt: jsonDateTime(json['uploadedAt']),
      lastUploadAttemptAt: jsonDateTime(json['lastUploadAttemptAt']),
      lastUploadErrorCode: _errorCodeValue(json['lastUploadErrorCode']),
      serverActivityId: jsonString(json['serverActivityId']),
    );
  }

  static const Object _unset = Object();
}

String _requiredString(Object? value, String field) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing local activity field: $field');
}

DateTime _requiredDateTime(Object? value, String field) {
  final parsed = jsonDateTime(value);
  if (parsed != null) {
    return parsed;
  }
  throw FormatException('Invalid local activity field: $field');
}

AppErrorCode? _errorCodeValue(Object? value) => appErrorCodeByName(value);
