import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// A PKCE (RFC 7636) code verifier paired with its S256-derived challenge.
///
/// Replaces the previous string-keyed map so callers access the two values as
/// non-nullable, self-documenting fields instead of `map['verifier']!`.
class PkcePair {
  const PkcePair({required this.verifier, required this.challenge});

  /// The high-entropy random code verifier, kept secret and sent only during
  /// the token exchange.
  final String verifier;

  /// `BASE64URL(SHA256(verifier))`, sent as `code_challenge` when starting the
  /// authorization flow.
  final String challenge;
}

/// Utility class for PKCE (Proof Key for Code Exchange) implementation
/// Implements RFC 7636 for enhanced security in OAuth flows
class PkceUtils {
  /// Generate a cryptographically random code verifier
  /// Returns a string of 43-128 characters from the base64url character set
  /// Characters: A-Z, a-z, 0-9, -, _ (valid base64url characters)
  static String generateCodeVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    final random = Random.secure();
    const length = 128; // Maximum length for better security

    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Generate code challenge from code verifier using S256 method
  /// Returns BASE64URL(SHA256(code_verifier))
  static String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Generate a fresh [PkcePair] (code verifier and its S256 challenge).
  static PkcePair generatePkce() {
    final verifier = generateCodeVerifier();
    final challenge = generateCodeChallenge(verifier);
    return PkcePair(verifier: verifier, challenge: challenge);
  }
}
