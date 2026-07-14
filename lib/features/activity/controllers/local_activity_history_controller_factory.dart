import 'package:endurain/core/services/app_services.dart';
import 'package:endurain/core/services/platform/share_service.dart';
import 'package:endurain/features/activity/controllers/local_activity_history_controller.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';

LocalActivityHistoryController createLocalActivityHistoryController({
  required AppServices services,
  LocalActivityRepository? repository,
  ActivityUploadService? uploadService,
  ShareService? shareService,
  ActivityRetentionSettingsRepository? retentionSettingsRepository,
  Future<void> Function(String localActivityId)? removeImportProvenance,
}) {
  return LocalActivityHistoryController(
    repository: repository ?? services.localActivities,
    uploadService: uploadService ?? services.activityUpload,
    shareService: shareService ?? services.share,
    retentionSettingsRepository:
        retentionSettingsRepository ?? services.activityRetentionSettings,
    diagnostics: services.diagnostics,
    removeImportProvenance:
        removeImportProvenance ??
        services.healthImportRepository.removeByLocalActivityId,
  );
}
