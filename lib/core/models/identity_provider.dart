// Identity Provider model for SSO/OAuth authentication
import 'package:endurain/core/utils/json_parsing.dart';

class IdentityProvider {
  final int id;
  final String slug;
  final String name;
  final String? icon;

  const IdentityProvider({
    required this.id,
    required this.slug,
    required this.name,
    this.icon,
  });

  /// Create IdentityProvider from JSON
  factory IdentityProvider.fromJson(Map<String, dynamic> json) {
    return IdentityProvider(
      id: jsonRequiredInt(json['id'], 'id'),
      name: jsonRequiredString(json['name'], 'name'),
      slug: jsonRequiredString(json['slug'], 'slug'),
      icon: jsonString(json['icon']),
    );
  }

  /// Convert IdentityProvider to JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug, 'icon': icon};
  }
}
