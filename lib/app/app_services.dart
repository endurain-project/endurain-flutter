import 'package:endurain/app/app_infrastructure.dart';
import 'package:endurain/app/modules/activity_module.dart';
import 'package:endurain/app/modules/auth_module.dart';
import 'package:endurain/app/modules/health_module.dart';
import 'package:endurain/app/modules/sensors_module.dart';
import 'package:endurain/app/modules/watch_module.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/features/account_migration/repositories/legacy_profile_alias_repository.dart';
import 'package:endurain/features/account_migration/services/legacy_profile_adoption_service.dart';
import 'package:endurain/features/activity/controllers/local_activity_history_controller.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:flutter/foundation.dart';

/// The application's composition root.
///
/// [AppServices] wires the shared [AppInfrastructure] and the per-feature
/// modules ([AuthModule], [SensorsModule], [ActivityModule], [HealthModule],
/// [WatchModule])
/// once, in dependency order, and exposes the modules themselves (`infra`,
/// `auth`, `activity`, ...) rather than a flat list of their services. Only
/// code under `lib/app` and `main` holds an [AppServices]: it builds each
/// screen from the pieces that screen needs (see `AppScreens`), and feature
/// code never sees it.
///
/// Each feature's wiring lives in its own module so this file stays small and
/// a contributor changing one feature does not touch the others. The two
/// cross-feature back-edges are resolved here rather than inside a module:
/// - sensors ↔ activity: [SensorsModule] receives a `canAutoReconnect` gate
///   backed by [ActivityModule.canAutoReconnectSensors]; the closure is lazy,
///   so either module can be built first.
/// - activity → health: the local-history controller's default health-import
///   cleanup is injected here (see [createLocalActivityHistoryController]).
/// - watch → health: Health Sync skips workouts a companion-watch session
///   already covers, through a lazy closure over [WatchModule.ledger].
class AppServices {
  AppServices({this.config = AppConfig.defaults});

  /// Runtime configuration shared by every service.
  final AppConfig config;

  late final AppInfrastructure _infra = AppInfrastructure(config: config);
  late final AuthModule _auth = AuthModule(_infra);

  // [SensorsModule] and [ActivityModule] reference each other; the gate closure
  // below is only evaluated at runtime, so the `late final` fields can be built
  // in either order without a cycle.
  late final SensorsModule _sensors = SensorsModule(
    infra: _infra,
    canAutoReconnect: () => _activity.canAutoReconnectSensors(),
  );
  late final ActivityModule _activity = ActivityModule(
    infra: _infra,
    auth: _auth,
    sensors: _sensors,
    // Lazy like the sensors gate: the adoption service depends on the health
    // module, which depends on this one.
    reconcileProfile: (profile) => legacyProfileAdoption.reapply(profile),
  );
  late final HealthModule _health = HealthModule(
    infra: _infra,
    auth: _auth,
    activity: _activity,
    // Lazy: the watch module is only built when Health Sync first asks.
    isRecordedElsewhere: (sourceId) =>
        _watch.ledger.containsHealthWorkout(sourceId),
  );
  late final WatchModule _watch = WatchModule(
    infra: _infra,
    activity: _activity,
  );

  // ── Session ────────────────────────────────────────────────────────────────

  final _ChangeSignal _connectionChanges = _ChangeSignal();

  /// Fires when the active server connection may have changed: sign-in,
  /// sign-out, session expiry, or the launch session check finishing.
  ///
  /// Long-lived screens (the bottom-navigation tabs stay alive across session
  /// changes) listen to refresh values tied to the connected server.
  Listenable get connectionChanges => _connectionChanges;

  /// Called by the root `App` whenever the session mode changes, so values
  /// scoped to the connected server are re-read.
  void notifyConnectionChanged() {
    _connectionChanges.emit();
    // The stored tile URL is scoped to the connection origin.
    tileServerUrlChanges.notifyChanged();
  }

  // ── Modules ────────────────────────────────────────────────────────────────

  /// Shared, feature-agnostic services (storage, diagnostics, platform
  /// integrations, app-wide locale and unit preferences).
  AppInfrastructure get infra => _infra;

  AuthModule get auth => _auth;
  SensorsModule get sensors => _sensors;
  ActivityModule get activity => _activity;
  HealthModule get health => _health;
  WatchModule get watch => _watch;

  // ── Cross-module builders ──────────────────────────────────────────────────

  /// Builds a route-owned [LocalActivityHistoryController].
  ///
  /// The default health-import cleanup is injected from [HealthModule],
  /// keeping that cross-feature edge in the root.
  LocalActivityHistoryController createLocalActivityHistoryController() {
    return _activity.createHistoryController(
      removeImportProvenance: _health.importRepository.removeByLocalActivityId,
      repository: _activity.localActivities,
      uploadService: _activity.upload,
      shareService: _infra.share,
      retentionSettingsRepository: _activity.retentionSettings,
    );
  }

  // ── Account migration ──────────────────────────────────────────────────────

  /// Moves the local data of a pre-v0.21 account (integer id) onto the UUID
  /// profile id the same account has after the server upgrade. It spans the
  /// activity and health features, so it is wired here.
  late final LegacyProfileAdoptionService legacyProfileAdoption =
      LegacyProfileAdoptionService(
        readSession: _auth.session.readSession,
        aliases: LegacyProfileAliasRepository(preferences: _infra.preferences),
        localActivities: _activity.localActivities,
        healthImports: _health.importRepository,
        healthSettings: _health.syncSettings,
        diagnostics: _infra.diagnostics,
      );

  // ── Map ────────────────────────────────────────────────────────────────────

  /// Shared by every [MapSettingsRepository] built here: notified when a tile
  /// URL is saved and when the connection (and so the origin-scoped key)
  /// changes, so the long-lived map reloads its tiles.
  late final TileServerUrlChanges tileServerUrlChanges = TileServerUrlChanges();

  /// Builds a [MapSettingsRepository] scoped to the active connection origin.
  MapSettingsRepository createMapSettingsRepository() {
    return MapSettingsRepository(
      preferences: _infra.preferences,
      config: config,
      activeConnectionOrigin: _auth.session.getAuthenticatedOrigin,
      changes: tileServerUrlChanges,
    );
  }
}

/// A [ChangeNotifier] that only signals; it carries no value.
class _ChangeSignal extends ChangeNotifier {
  void emit() => notifyListeners();
}
