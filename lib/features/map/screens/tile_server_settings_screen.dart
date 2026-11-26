import 'dart:async';

import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/validators.dart';
import 'package:endurain/features/map/controllers/tile_server_settings_controller.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/layout/readable_content.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:material_ui/material_ui.dart';

/// Lets a signed-in user change the tile server the map draws from.
///
/// The value is stored for the connected server only. Signing in again
/// replaces it with the server's own tile setting (see
/// `MapSettingsRepository.saveFromServerSettings`).
class TileServerSettingsScreen extends StatefulWidget {
  const TileServerSettingsScreen({
    super.key,
    this.controller,
    this.createController,
  }) : assert(
         controller != null || createController != null,
         'Pass a controller or a factory for one.',
       );

  /// Injected controller (tests); otherwise one is built with
  /// [createController] and owned by the screen.
  final TileServerSettingsController? controller;
  final TileServerSettingsController Function()? createController;

  @override
  State<TileServerSettingsScreen> createState() =>
      _TileServerSettingsScreenState();
}

class _TileServerSettingsScreenState extends State<TileServerSettingsScreen>
    with OwnedControllers {
  final _formKey = GlobalKey<FormState>();
  final _tileServerUrlController = TextEditingController();
  late final TileServerSettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = registerController(
      widget.controller,
      () => widget.createController!(),
    );
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _tileServerUrlController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _controller.load();
    if (mounted && !_controller.hasLoadError) {
      _tileServerUrlController.text = _controller.tileServerUrl;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final tileUrl = _tileServerUrlController.text.trim();

    if (!await _confirmTileHostIfNeeded(tileUrl, l10n)) {
      return;
    }

    try {
      await _controller.saveTileServerUrl(tileUrl);

      if (mounted) {
        await DialogUtils.showSuccessDialog(
          context,
          l10n.savedSuccessfully,
          onDismiss: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        await DialogUtils.showErrorDialog(context, e);
      }
    }
  }

  /// Applies the controller's tile-host policy and shows the matching UI.
  /// Returns true when saving may proceed.
  Future<bool> _confirmTileHostIfNeeded(
    String tileUrl,
    AppLocalizations l10n,
  ) async {
    switch (_controller.evaluateTileHost(tileUrl)) {
      case TileServerHostDecision.allowed:
        return true;
      case TileServerHostDecision.blocked:
        // Managed policy: reject disallowed hosts without any confirmation.
        if (mounted) {
          await DialogUtils.showErrorDialog(
            context,
            l10n.tileServerHostWarningTitle,
          );
        }
        return false;
      case TileServerHostDecision.needsConfirmation:
        if (!mounted) {
          return false;
        }
        return DialogUtils.showConfirmDialog(
          context,
          title: l10n.tileServerHostWarningTitle,
          message: l10n.tileServerHostWarningMessage,
          confirmText: l10n.save,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final noteStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    return AdaptiveScaffold(
      title: l10n.mapTilesSettingsTitle,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: AdaptiveLoadingIndicator());
          }
          if (_controller.hasLoadError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(UIConstants.paddingStandard),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdaptiveEmptyStateText(
                      message: l10n.mapTilesSettingsLoadFailed,
                    ),
                    const SizedBox(height: UIConstants.paddingStandard),
                    AdaptiveButton(
                      label: l10n.tryAgain,
                      onPressed: _initialize,
                    ),
                  ],
                ),
              ),
            );
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: readableContentPadding(context),
              children: [
                AdaptiveTextFormField(
                  label: l10n.tileServerUrl,
                  placeholder: l10n.tileServerUrlHint,
                  controller: _tileServerUrlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.validateTileServerUrl(
                    value,
                    l10n,
                    config: _controller.config,
                  ),
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: UIConstants.paddingSmall),
                Text(l10n.mapTilesSettingsNote, style: noteStyle),
                const SizedBox(height: UIConstants.paddingLarge),
                AdaptiveButton(
                  label: l10n.save,
                  onPressed: _save,
                  expand: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
