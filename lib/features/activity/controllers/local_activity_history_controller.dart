import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:flutter/foundation.dart';

class LocalActivityHistoryController extends ChangeNotifier {
  LocalActivityHistoryController({
    required LocalActivityRepository repository,
    required ActivityUploadService uploadService,
    ActivityRetentionSettingsRepository? retentionSettingsRepository,
    DateTime Function()? now,
  }) : _repository = repository,
       _uploadService = uploadService,
       _retentionSettingsRepository = retentionSettingsRepository,
       _now = now ?? DateTime.now;

  static const int _pageSize = 20;

  final LocalActivityRepository _repository;
  final ActivityUploadService _uploadService;
  final ActivityRetentionSettingsRepository? _retentionSettingsRepository;
  final DateTime Function() _now;

  List<LocalActivityRecord> _records = const [];
  Set<String> _busyRecordIds = const {};
  bool _isLoading = false;
  Object? _error;
  bool _isDisposed = false;
  bool _hasMore = true;

  List<LocalActivityRecord> get records => List.unmodifiable(_records);

  bool get isLoading => _isLoading;

  Object? get error => _error;

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

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    _notifyListeners();
    try {
      final page = await _repository.listPage(offset: 0, limit: _pageSize);
      _records = page;
      _hasMore = page.length == _pageSize;
    } catch (error) {
      _error = error;
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
      _error = error;
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<void> refresh() => load();

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
      await load();
    } catch (_) {
      await load();
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
      await load();
    } finally {
      _setBusy(id, busy: false);
    }
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
