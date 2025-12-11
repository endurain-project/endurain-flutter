import 'package:endurain/l10n/app_localizations.dart';

/// Validation utility functions
class Validators {
  /// Validate that a field is not empty
  static String? validateRequired(
    String? value,
    AppLocalizations l10n,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return l10n.requiredField;
    }
    return null;
  }

  /// Validate that a URL is properly formatted
  static String? validateUrl(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.requiredField;
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasScheme ||
        (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return l10n.invalidUrl;
    }
    return null;
  }
}
