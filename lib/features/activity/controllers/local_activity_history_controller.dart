import 'dart:ui';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/platform/share_service.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/features/activity/services/gpx_route_parser.dart';
import 'package:flutter/foundation.dart';

class LocalActivityHistoryController extends ChangeNotifier {
  LocalActivityHistoryController({
    required this._repository,
    required ActivityUploadService uploadService,
    required this._shareService,
    this._retentionSettingsRepository,
    DateTime Function()? now,
    DiagnosticsRecorder? diagnostics,
    Future<void> Function(String localActivityId)? removeImportProvenance,
  }) : _uploadService = uploadService,
       _now = now ?? DateTime.now,
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder(),
       _removeImportProvenance = removeImportProvenance;

  static const int _pageSize = 20;

  final LocalActivityRepository _repository;
  final ActivityUploadService _uploadService;
  final ShareService _shareService;
  final ActivityRetentionSettingsRepository? _retentionSettingsRepository;
  final DateTime Function() _now;
  final DiagnosticsRecorder _diagnostics;
  final Future<void> Function(String localActivityId)? _removeImportProvenance;

  List<LocalActivityRecord> _records = const [];
  Set<String> _busyRecordIds = const {};
  bool _isLoading = false;
  AppException? _error;
  bool _isDisposed = false;
  bool _hasMore = true;

  List<LocalActivityRecord> get records => List.unmodifiable(_records);

  bool get isLoading => _isLoading;

  AppException? get error => _error;

  bool get hasMore => _hasMore;

  bool isBusy(String id) => _busyRecordIds.contains(id);

  LocalActivityRecord? recordById(String id) {
    for (final record in _records) {
      if (record.id == id) {
        return record;
      }
    }
    return null;
  }

  Future<bool> hasGpx(LocalActivityRecord record) {
    return _repository.hasGpx(record);
  }

  /// Loads and parses the GPS route for [record] so a map can be drawn from the
  /// retained GPX file. Returns `null` when the file is missing (e.g. deleted
  /// after upload) or contains no track points, so callers can hide the map
  /// without special-casing errors.
  Future<GpxRoute?> loadRoute(LocalActivityRecord record) async {
    try {
      if (!await hasGpx(record)) {
        return null;
      }
      final gpx = await _repository.readGpxContents(record);
      return const GpxRouteParser().parse(gpx);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    _notifyListeners();
    try {
      final page = await _repository.listPage(offset: 0, limit: _pageSize);
      _records = page;
      _hasMore = page.length == _pageSize;
    } catch (error) {
      _error = _asAppException(error);
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  /// Loads one record for a details route without depending on list paging.
  Future<void> loadRecord(String id) async {
    _isLoading = true;
    _error = null;
    _notifyListeners();
    try {
      final record = await _repository.get(id);
      _records = record == null ? const [] : [record];
      _hasMore = false;
    } catch (error) {
      _error = _asAppException(error);
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) {
      return;
    }
    _isLoading = true;
    _notifyListeners();
    try {
      final page = await _repository.listPage(
        offset: _records.length,
        limit: _pageSize,
      );
      _records = [..._records, ...page];
      _hasMore = page.length == _pageSize;
    } catch (error) {
      _error = _asAppException(error);
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<void> exportGpx(
    String id, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    final record = await _repository.get(id);
    if (record == null) {
      throw const AppException(AppErrorCode.activityLocalActivityNotFound);
    }
    final path = await _repository.readGpxFilePath(record);
    await _shareService.shareFiles(
      [path],
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<void> retryUpload(String id) async {
    if (_busyRecordIds.contains(id)) {
      return;
    }
    final record = await _repository.get(id);
    if (record == null) {
      throw const AppException(AppErrorCode.activityLocalActivityNotFound);
    }

    _setBusy(id, busy: true);
    try {
      await _uploadService.performUploadAttempt(
        record: record,
        repository: _repository,
        retentionRepository: _retentionSettingsRepository,
        now: _now,
      );
      await _refreshRecord(id);
    } catch (_) {
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.activityUploadRetryFailed,
        details: {'id': id},
      );
      await _refreshRecord(id);
      rethrow;
    } finally {
      _setBusy(id, busy: false);
    }
  }

  Future<void> delete(String id) async {
    if (_busyRecordIds.contains(id)) {
      return;
    }
    _setBusy(id, busy: true);
    try {
      await _repository.delete(id);
      await _removeImportProvenance?.call(id);
      _records = _records.where((record) => record.id != id).toList();
      _notifyListeners();
    } finally {
      _setBusy(id, busy: false);
    }
  }

  Future<void> _refreshRecord(String id) async {
    final updated = await _repository.get(id);
    final index = _records.indexWhere((record) => record.id == id);
    if (updated == null) {
      if (index >= 0) {
        _records = [..._records]..removeAt(index);
      }
      _notifyListeners();
      return;
    }
    if (index < 0) {
      _records = [updated, ..._records];
    } else {
      _records = [..._records]..[index] = updated;
    }
    _notifyListeners();
  }

  void _setBusy(String id, {required bool busy}) {
    final ids = {..._busyRecordIds};
    if (busy) {
      ids.add(id);
    } else {
      ids.remove(id);
    }
    _busyRecordIds = ids;
    _notifyListeners();
  }

  /// Normalizes any caught error into a typed [AppException] so the controller
  /// only ever exposes a typed error the UI can localize.
  AppException _asAppException(Object error) {
    return error is AppException
        ? error
        : AppException(AppErrorCode.activityLocalLoadFailed, cause: error);
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
