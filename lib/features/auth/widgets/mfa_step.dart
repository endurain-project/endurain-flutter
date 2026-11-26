import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/features/auth/widgets/mfa_code_field.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:material_ui/material_ui.dart';

/// What the user has entered at the MFA step: the code, its kind, and why
/// the last code failed.
///
/// Owned by the login screen rather than [MfaStep], so it outlives the
/// loading indicator that replaces the step while a code is checked: a
/// rejected backup code leaves the step on backup codes.
class MfaCodeEntry extends ChangeNotifier {
  MfaCodeEntry() {
    code.addListener(_clearErrorOnInput);
  }

  /// The characters typed, without a backup code's dash.
  final code = TextEditingController();

  MfaCodeKind _kind = MfaCodeKind.totp;
  String? _error;

  MfaCodeKind get kind => _kind;

  /// Why the last code failed; cleared as soon as the user types again.
  String? get error => _error;

  set error(String? value) {
    if (value == _error) return;
    _error = value;
    notifyListeners();
  }

  /// The code to send, or `null` while some boxes are empty.
  String? get completeCode {
    final typed = _kind.normalize(code.text);
    return typed.length == _kind.length ? _kind.toSubmission(typed) : null;
  }

  /// Switches between an authenticator code and a backup code.
  void toggleKind() {
    _kind = _kind == MfaCodeKind.totp
        ? MfaCodeKind.backupCode
        : MfaCodeKind.totp;
    _error = null;
    code.clear();
    notifyListeners();
  }

  /// Back to an empty authenticator code, for a new sign-in.
  void reset() {
    _kind = MfaCodeKind.totp;
    _error = null;
    code.clear();
    notifyListeners();
  }

  void _clearErrorOnInput() {
    if (code.text.isNotEmpty) {
      error = null;
    }
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }
}

/// The MFA step of the login screen: the code boxes, the switch to a backup
/// code, and the Verify and Back buttons.
class MfaStep extends StatelessWidget {
  const MfaStep({
    super.key,
    required this.entry,
    required this.acceptsBackupCodes,
    required this.onSubmit,
    required this.onBack,
  });

  final MfaCodeEntry entry;

  /// Whether the server takes a backup code, which offers the switch.
  final bool acceptsBackupCodes;

  /// Sends the code; also runs once the last box is filled.
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: entry,
      builder: (context, _) {
        final usingBackupCode = entry.kind == MfaCodeKind.backupCode;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MfaCodeField(
              // A new field per kind, so the keyboard switches with it.
              key: ValueKey(entry.kind),
              controller: entry.code,
              kind: entry.kind,
              label: usingBackupCode ? l10n.mfaBackupCode : l10n.mfaCode,
              instruction: usingBackupCode
                  ? l10n.mfaBackupCodeHint
                  : l10n.mfaCodeHint,
              errorText: entry.error,
              autofocus: true,
              onCompleted: onSubmit,
              onSubmitted: onSubmit,
            ),
            if (acceptsBackupCodes || usingBackupCode) ...[
              const SizedBox(height: UIConstants.paddingCompact),
              Center(
                child: AdaptiveButton(
                  label: usingBackupCode
                      ? l10n.mfaUseAuthenticatorCode
                      : l10n.mfaUseBackupCode,
                  onPressed: entry.toggleKind,
                  variant: AdaptiveButtonVariant.secondary,
                ),
              ),
            ],
            const SizedBox(height: UIConstants.paddingLarge),
            AdaptiveButton(
              label: l10n.verify,
              onPressed: onSubmit,
              expand: true,
            ),
            const SizedBox(height: UIConstants.paddingStandard),
            AdaptiveButton(
              label: l10n.back,
              onPressed: onBack,
              variant: AdaptiveButtonVariant.secondary,
              expand: true,
            ),
          ],
        );
      },
    );
  }
}
