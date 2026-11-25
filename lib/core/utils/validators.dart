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
  /// Self-hosted instances accept both `http://` and `https://` URLs. For the
  /// configured Endurain Cloud origin (see
  /// [AppConfig.allowInsecureTransportFor]), plain `http://` URLs are rejected
  /// with [AppLocalizations.invalidUrl] before any network call is made.
  static String? validateUrl(
    String? value,
    AppLocalizations l10n, {
    required AppConfig config,
  }) {
    if (value == null || value.trim().isEmpty) {
      return l10n.requiredField;
    }
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return l10n.invalidUrl;
    }
    if (!config.allowInsecureTransportFor(trimmed) && uri.isScheme('http')) {
      return l10n.invalidUrl;
    }
    return null;
  }

  /// Validate a map tile-server URL template.
  ///
  /// Applies [validateUrl] and then requires a template the map can fill (see
  /// [isTileUrlTemplate]), so a URL without `{z}`/`{x}`/`{y}` or with an
  /// unsupported placeholder such as `{apikey}` is rejected with
  /// [AppLocalizations.invalidUrl] instead of failing on every tile.
  static String? validateTileServerUrl(
    String? value,
    AppLocalizations l10n, {
    required AppConfig config,
  }) {
    final urlError = validateUrl(value, l10n, config: config);
    if (urlError != null) {
      return urlError;
    }
    return isTileUrlTemplate(value!) ? null : l10n.invalidUrl;
  }

  /// Placeholders the map's tile layer can substitute: zoom, column, row,
  /// subdomain, retina suffix and the `{d}` tile dimension.
  static const _supportedTilePlaceholders = {'z', 'x', 'y', 's', 'r', 'd'};

  /// Placeholders the tile URL must contain to address a single tile.
  static const _requiredTilePlaceholders = {'z', 'x', 'y'};

  /// Matches a `{name}` placeholder, using the same pattern as the tile layer.
  static final _tilePlaceholder = RegExp(r'\{([^{}]*)\}');

  /// Whether [url] is a tile URL template the map can fill: it contains the
  /// `{z}`, `{x}` and `{y}` placeholders and no placeholder other than
  /// `{z}`, `{x}`, `{y}`, `{s}`, `{r}` and `{d}`.
  ///
  /// Checks the raw text, so a `{s}` subdomain placeholder in the host (which
  /// [Uri.parse] percent-encodes) is recognised. Language-free so it can also
  /// guard the repository boundary.
  static bool isTileUrlTemplate(String url) {
    final placeholders = _tilePlaceholder
        .allMatches(url)
        .map((match) => match.group(1)!)
        .toSet();
    return placeholders.containsAll(_requiredTilePlaceholders) &&
        _supportedTilePlaceholders.containsAll(placeholders);
  }
}
