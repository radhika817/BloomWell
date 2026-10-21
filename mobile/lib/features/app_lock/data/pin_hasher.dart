import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Cryptographic helper for generating salts and slow PBKDF2 PIN hashes.
///
/// Implements PBKDF2 using HMAC-SHA256 with 50,000 iterations to protect
/// against offline brute force, combined with constant-time verification.
class PinHasher {
  PinHasher._();

  static const int iterations = 50000;
  static const int keyLength = 32;

  /// Generates a cryptographically secure random base64url-encoded salt.
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Hashes a PIN using PBKDF2-HMAC-SHA256 with [iterations] iterations.
  static String hashPin(String pin, String salt) {
    final saltBytes = utf8.encode(salt);
    final pinBytes = utf8.encode(pin);

    // Standard RFC 2898 single-block derivation for 32-byte key
    final block1Input = Uint8List(saltBytes.length + 4)
      ..setRange(0, saltBytes.length, saltBytes)
      ..[saltBytes.length + 3] = 1;

    final hmac = Hmac(sha256, pinBytes);
    var u = hmac.convert(block1Input).bytes;
    final result = Uint8List.fromList(u);

    for (int i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return base64Url.encode(result);
  }

  /// Verifies a candidate [pin] against the stored [salt] and [expectedHash]
  /// in constant time to prevent side-channel timing leaks.
  static bool verifyPin({
    required String pin,
    required String salt,
    required String expectedHash,
  }) {
    final computedHash = hashPin(pin, salt);
    return constantTimeEquals(computedHash, expectedHash);
  }

  /// Constant-time string equality check.
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
