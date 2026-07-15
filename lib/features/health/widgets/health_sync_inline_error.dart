import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/error_localizations.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Inline, centered error message shown within a health-sync workout list
/// surface. Shared by the "Available" and "Imported" tab views.
class HealthSyncInlineError extends StatelessWidget {
  const HealthSyncInlineError({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: UIConstants.paddingStandard),
      child: Text(
        localizedErrorMessage(error, l10n),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
