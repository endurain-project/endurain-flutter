import 'dart:async';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:endurain/features/health/models/health_imported_workout.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_sync_state.dart';
import 'package:endurain/features/health/services/health_sync_service.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

/// Controller that drives the health-sync UI.
///
/// Holds a [HealthSyncState] snapshot and exposes async mutators that update
/// it via `notifyListeners`. Consumers must call [loadStatus] on mount.
///
/// Route-owned in production. A screen that creates it must dispose it; an
/// injected controller remains owned by the caller.
class HealthSyncController extends SafeNotifier {
  HealthSyncController({
    required this._service,
    DiagnosticsRecorder? diagnostics,
    Stream<void>? uploadCompletedSignal,
  }) : _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder() {
    _uploadCompletedSubscription = uploadCompletedSignal?.listen((_) {
      if (_state.importedWorkouts.isNotEmpty ||
          _state.selectedView == HealthSyncView.imported) {
        if (_state.isLoadingImported) {
          _refreshImportedAfterCurrentLoad = true;
        } else {
          unawaited(loadImported());
        }
      }
    });
  }

  final HealthSyncService _service;
  final DiagnosticsRecorder _diagnostics;
  bool _refreshImportedAfterCurrentLoad = false;
  StreamSubscription<void>? _uploadCompletedSubscription;

  HealthSyncState _state = const HealthSyncState();
  static const int _importedPageSize = 20;

  /// The current state snapshot.
  HealthSyncState get state => _state;

  // ── Status ─────────────────────────────────────────────────────────────────

  /// Checks SDK availability and (if already authorized) updates auth status.
  ///
  /// Safe to call on every screen mount; no-ops if the SDK is unsupported.
  ///
  /// When access is already granted, the importable workout list is fetched
  /// automatically so the screen never requires a manual "find workouts" tap.
  Future<void> loadStatus() async {
    _update(_state.copyWith(isCheckingStatus: true, error: null));
    try {
      final sdkStatus = await _service.status();
      HealthAuthorizationStatus authStatus =
          HealthAuthorizationStatus.notDetermined;
      var accessDetails = const HealthDataAccessDetails.systemManaged();
      var autoSyncOnResume = false;
      DateTime? lastSyncAt;
      if (sdkStatus == HealthSdkStatus.available) {
        authStatus = await _service.currentAuthorizationStatus();
        accessDetails = await _service.accessDetails();
        autoSyncOnResume = await _service.isAutoSyncOnResumeEnabled();
        lastSyncAt = await _service.lastSyncAt();
      }
      _update(
        _state.copyWith(
          sdkStatus: sdkStatus,
          authStatus: authStatus,
          accessDetails: accessDetails,
          autoSyncOnResume: autoSyncOnResume,
          lastSyncAt: lastSyncAt,
          isCheckingStatus: false,
          error: null,
        ),
      );
      if (sdkStatus == HealthSdkStatus.available &&
          authStatus == HealthAuthorizationStatus.granted) {
        await loadImportableWorkouts();
      }
    } catch (error) {
      final e = _asAppException(error);
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthLoadStatusFailed,
        details: {'code': e.code.name},
      );
      _update(_state.copyWith(isCheckingStatus: false, error: e));
    }
  }

  /// Enables or disables automatic import of new workouts on app resume.
  Future<void> setAutoSyncOnResume(bool enabled) async {
    if (_state.isUpdatingAutoSync) return;
    _update(_state.copyWith(isUpdatingAutoSync: true, error: null));
    try {
      await _service.setAutoSyncOnResumeEnabled(enabled);
      _update(
        _state.copyWith(
          autoSyncOnResume: enabled,
          isUpdatingAutoSync: false,
          error: null,
        ),
      );
    } catch (error) {
      final e = _asAppException(error);
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthAutoSyncSettingFailed,
        details: {'code': e.code.name},
      );
      _update(_state.copyWith(isUpdatingAutoSync: false, error: e));
    }
  }

  // ── Authorization ──────────────────────────────────────────────────────────

  /// Requests health data access from the platform.
  ///
  /// On completion the state reflects the new [HealthAuthorizationStatus]. When
  /// access is granted the importable workout list is fetched automatically.
  Future<void> requestAccess() async {
    _update(_state.copyWith(isCheckingStatus: true, error: null));
    try {
      final authStatus = await _service.requestAccess();
      final accessDetails = await _service.accessDetails();
      // When denied, surface an error so the UI shows feedback rather than
      // silently resetting to the same "Connect" button with no message.
      // This covers both an explicit user denial and the Health Connect
      // sideloading restriction (dialog never shown, returns false immediately).
      _update(
        _state.copyWith(
          authStatus: authStatus,
          accessDetails: accessDetails,
          isCheckingStatus: false,
          error: authStatus == HealthAuthorizationStatus.denied
              ? const AppException(AppErrorCode.healthPermissionDenied)
              : null,
        ),
      );
      if (authStatus == HealthAuthorizationStatus.granted) {
        await loadImportableWorkouts();
      }
    } catch (error) {
      final e = _asAppException(error);
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthRequestAccessFailed,
        details: {'code': e.code.name},
      );
      _update(_state.copyWith(isCheckingStatus: false, error: e));
    }
  }

  /// Directs the user to the app store to install the health provider
  /// (Google Health Connect on Android).
  ///
  /// After returning from the store the SDK status is re-checked so the UI
  /// can advance to the authorization step once the provider is installed.
  Future<void> installHealthConnect() async {
    _update(_state.copyWith(isCheckingStatus: true, error: null));
    try {
      await _service.installHealthConnect();
      await loadStatus();
    } catch (error) {
      final e = _asAppException(error);
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthInstallProviderFailed,
        details: {'code': e.code.name},
      );
      _update(_state.copyWith(isCheckingStatus: false, error: e));
    }
  }

  Future<void> disconnect() async {
    try {
      await _service.disconnect();
      _update(
        const HealthSyncState(
          sdkStatus: HealthSdkStatus.available,
          authStatus: HealthAuthorizationStatus.notDetermined,
          isCheckingStatus: false,
        ),
      );
    } catch (error) {
      final appError = _asAppException(error);
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthDisconnectFailed,
        details: {'code': appError.code.name},
      );
      _update(_state.copyWith(error: appError));
    }
  }

  // ── Importable workouts ────────────────────────────────────────────────────

  /// Fetches the importable workout list (read-only; no writes occur).
  ///
  /// Populates [HealthSyncState.importableWorkouts] and clears the current
  /// selection. Does not clear [HealthSyncState.error] from prior imports so
  /// the UI can keep showing results while refreshing.
  Future<void> loadImportableWorkouts() async {
    _update(_state.copyWith(isLoadingWorkouts: true));
    try {
      final page = await _service.loadAvailable(range: _state.selectedRange);
      final lastSyncAt = await _service.lastSyncAt();
      _update(
        _state.copyWith(
          importableWorkouts: page.items,
          selectedSourceIds: const {},
          isLoadingWorkouts: false,
          availableHasMore: page.hasMore,
          routeConsentDeniedCount: _service.routeConsentDeniedCount,
          lastSyncAt: lastSyncAt,
          error: null,
        ),
      );
    } on AppException catch (e) {
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthLoadImportableFailed,
        details: {'code': e.code.name},
      );
      _update(
        _state.copyWith(
          authStatus: e.code == AppErrorCode.healthReadFailed
              ? HealthAuthorizationStatus.notDetermined
              : _state.authStatus,
          isLoadingWorkouts: false,
          error: e,
        ),
      );
    }
  }

  Future<void> setRange(HealthImportRange range) async {
    if (_state.selectedRange == range) return;
    _update(_state.copyWith(selectedRange: range, selectedSourceIds: const {}));
    await loadImportableWorkouts();
  }

  Future<void> loadMoreAvailable() async {
    if (_state.isLoadingMoreAvailable || !_state.availableHasMore) return;
    _update(_state.copyWith(isLoadingMoreAvailable: true));
    try {
      final page = await _service.loadMoreAvailable();
      _update(
        _state.copyWith(
          importableWorkouts: page.items,
          availableHasMore: page.hasMore,
          isLoadingMoreAvailable: false,
          routeConsentDeniedCount: _service.routeConsentDeniedCount,
          error: null,
        ),
      );
    } catch (error) {
      final appError = _asAppException(error);
      _update(_state.copyWith(isLoadingMoreAvailable: false, error: appError));
    }
  }

  Future<void> selectView(HealthSyncView view) async {
    if (_state.selectedView == view) return;
    _update(_state.copyWith(selectedView: view, error: null));
    if (view == HealthSyncView.imported && _state.importedWorkouts.isEmpty) {
      await loadImported();
    }
  }

  Future<void> loadImported({bool reset = true}) async {
    if (_state.isLoadingImported) return;
    _update(_state.copyWith(isLoadingImported: true));
    try {
      final current = reset
          ? const <HealthImportedWorkout>[]
          : _state.importedWorkouts;
      final page = await _service.listImported(
        offset: current.length,
        limit: _importedPageSize,
      );
      _update(
        _state.copyWith(
          importedWorkouts: [...current, ...page.items],
          importedHasMore: page.hasMore,
          isLoadingImported: false,
          error: null,
        ),
      );
      _runPendingImportedRefresh();
    } catch (error) {
      _update(
        _state.copyWith(
          isLoadingImported: false,
          error: _asAppException(error),
        ),
      );
      _runPendingImportedRefresh();
    }
  }

  void _runPendingImportedRefresh() {
    if (!_refreshImportedAfterCurrentLoad || isDisposed) return;
    _refreshImportedAfterCurrentLoad = false;
    unawaited(loadImported());
  }

  Future<void> restoreMissingImport(HealthImportedWorkout imported) async {
    try {
      await _service.restoreMissingImport(imported);
      await loadImported();
      _update(_state.copyWith(selectedView: HealthSyncView.available));
      await loadImportableWorkouts();
    } catch (error) {
      _update(_state.copyWith(error: _asAppException(error)));
    }
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  /// Toggles [sourceId] in / out of the pending selection.
  ///
  /// Non-importable (no-route) workouts are silently ignored.
  void toggleSelection(String sourceId) {
    if (!_isImportable(sourceId)) return;
    final current = Set<String>.of(_state.selectedSourceIds);
    if (current.contains(sourceId)) {
      current.remove(sourceId);
    } else {
      current.add(sourceId);
    }
    _update(_state.copyWith(selectedSourceIds: current));
  }

  /// Selects all route-bearing (importable) workouts.
  void selectAll() {
    final all = _state.importableWorkouts
        .where((w) => w.hasRoute)
        .map((w) => w.sourceId)
        .toSet();
    _update(_state.copyWith(selectedSourceIds: all));
  }

  /// Clears the current selection.
  void clearSelection() {
    _update(_state.copyWith(selectedSourceIds: const {}));
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  /// Imports the currently selected workouts.
  ///
  /// On completion, the importable list is refreshed and the selection is
  /// cleared.
  Future<void> importSelected() async {
    if (_state.selectedSourceIds.isEmpty) return;
    _update(_state.copyWith(isImporting: true, error: null));
    try {
      final result = await _service.importWorkouts(_state.selectedSourceIds);
      await _refreshAfterImport(result.imported, result.failed);
    } catch (error) {
      final e = _asAppException(error);
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthImportSelectedFailed,
        details: {'code': e.code.name},
      );
      _update(_state.copyWith(isImporting: false, error: e));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _isImportable(String sourceId) {
    return _state.importableWorkouts.any(
      (w) => w.sourceId == sourceId && w.hasRoute,
    );
  }

  Future<void> _refreshAfterImport(
    int importedCount,
    int failedImportCount,
  ) async {
    try {
      final page = await _service.loadAvailable(range: _state.selectedRange);
      final importedPage = _state.importedWorkouts.isEmpty
          ? null
          : await _service.listImported(limit: _importedPageSize);
      final lastSyncAt = await _service.lastSyncAt();
      _update(
        _state.copyWith(
          importableWorkouts: page.items,
          importedWorkouts: importedPage?.items ?? _state.importedWorkouts,
          selectedSourceIds: const {},
          isImporting: false,
          importedCount: importedCount,
          failedImportCount: failedImportCount,
          routeConsentDeniedCount: _service.routeConsentDeniedCount,
          availableHasMore: page.hasMore,
          importedHasMore: importedPage?.hasMore ?? _state.importedHasMore,
          lastSyncAt: lastSyncAt,
          error: failedImportCount == 0
              ? null
              : const AppException(AppErrorCode.healthImportFailed),
        ),
      );
    } on AppException catch (e) {
      _update(
        _state.copyWith(
          selectedSourceIds: const {},
          isImporting: false,
          importedCount: importedCount,
          failedImportCount: failedImportCount,
          error: e,
        ),
      );
    }
  }

  void _update(HealthSyncState next) {
    _state = next;
    notify();
  }

  AppException _asAppException(Object error) {
    return error is AppException
        ? error
        : AppException(AppErrorCode.healthImportFailed, cause: error);
  }

  @override
  void dispose() {
    unawaited(_uploadCompletedSubscription?.cancel());
    _uploadCompletedSubscription = null;
    // Drop the route-scoped importable-list cursor so its candidate cache does
    // not linger on the app-lifetime service after this route is torn down.
    unawaited(_service.clearDiscoveryCache());
    super.dispose();
  }
}
