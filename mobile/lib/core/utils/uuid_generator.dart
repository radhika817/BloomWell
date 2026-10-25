import 'dart:math';

/// Generates a cryptographically secure RFC-4122 v4 UUID string.
/// Used to provide unique `client_id`s for idempotent write operations.
String generateUuidV4() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  values[6] = (values[6] & 0x0f) | 0x40; // version 4
  values[8] = (values[8] & 0x3f) | 0x80; // variant
  final hex = [
    for (int i = 0; i < 16; i++) values[i].toRadixString(16).padLeft(2, '0')
  ].join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}
