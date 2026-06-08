import 'package:endurain/core/config/app_config.dart';
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

  /// Validate that a URL is properly formatted.
  ///
  /// In [AppTransportMode.selfHosted] (the default), both `http://` and
  /// `https://` URLs are accepted.
  ///
  /// In [AppTransportMode.managed], plain `http://` URLs are rejected with
  /// [AppLocalizations.invalidUrl] before any network call is made.
  static String? validateUrl(
    String? value,
    AppLocalizations l10n, {
    AppConfig config = AppConfig.defaults,
  }) {
    if (value == null || value.trim().isEmpty) {
      return l10n.requiredField;
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasScheme ||
        (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return l10n.invalidUrl;
    }
    if (!config.allowInsecureTransport && uri.isScheme('http')) {
      return l10n.invalidUrl;
    }
    return null;
  }
}
