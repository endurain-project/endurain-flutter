import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/features/account_migration/services/legacy_profile_adoption_service.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Asks whether the local data of a pre-v0.21 account belongs to the account
/// that just signed in. A [ConfirmLegacyProfile] for
/// `LegacyProfileAdoptionService.resolveAfterSignIn`.
///
/// The barrier does not dismiss it, so a stray tap is not read as "not mine";
/// a back gesture returns `null` and the question comes back at the next
/// sign-in.
Future<bool?> confirmLegacyProfileAdoption(
  BuildContext context,
  LegacyProfileCandidate candidate,
) async {
  if (!context.mounted) {
    return null;
  }
  final l10n = AppLocalizations.of(context)!;
  final username = candidate.username;
  return DialogUtils.showChoiceDialog(
    context,
    title: l10n.legacyDataTitle,
    message: username == null || username.isEmpty
        ? l10n.legacyDataMessage
        : l10n.legacyDataMessageWithUsername(username),
    confirmText: l10n.legacyDataConfirm,
    cancelText: l10n.legacyDataDecline,
    barrierDismissible: false,
  );
}
