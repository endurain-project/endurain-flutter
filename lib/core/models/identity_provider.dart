// Identity Provider model for SSO/OAuth authentication
import 'package:endurain/core/utils/json_parsing.dart';

class IdentityProvider {
  /// The provider's id: a UUID string on Endurain v0.21+. Opaque; never parsed,
  /// sorted or compared as a number.
  final String id;
  final String slug;
  final String name;

  /// A built-in icon key (`authelia`, `authentik`, `casdoor`, `keycloak`,
  /// `pocketid`), or `null`.
  final String? icon;

  /// Whether an administrator uploaded an icon, served at
  /// `GET /public/idp/{slug}/icon`.
  final bool iconUploaded;

  const IdentityProvider({
    required this.id,
    required this.slug,
    required this.name,
    this.icon,
    this.iconUploaded = false,
  });

  /// Create IdentityProvider from JSON
  factory IdentityProvider.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return IdentityProvider(
      id: id is int ? '$id' : jsonRequiredString(id, 'id'),
      name: jsonRequiredString(json['name'], 'name'),
      slug: jsonRequiredString(json['slug'], 'slug'),
      icon: jsonString(json['icon']),
      iconUploaded: jsonBool(json['icon_uploaded']) ?? false,
    );
  }

  /// Convert IdentityProvider to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon': icon,
      'icon_uploaded': iconUploaded,
    };
  }
}
