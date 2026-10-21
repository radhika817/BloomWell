import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/app_lock_config.dart';

/// Persists App Lock security parameters in FlutterSecureStorage, scoped by user ID.
///
/// Ensures PIN data, attempts, lockout timers, and preferences are isolated
/// per account and wiped on logout so a second user on the device starts clean.
class AppLockStorage {
  AppLockStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _key(String userId, String suffix) =>
      'bloomwell_lock_${userId}_$suffix';

  Future<String?> getSalt(String userId) =>
      _storage.read(key: _key(userId, 'salt'));

  Future<String?> getHash(String userId) =>
      _storage.read(key: _key(userId, 'hash'));

  Future<bool> isPinSet(String userId) async {
    final hash = await getHash(userId);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> savePin({
    required String userId,
    required String salt,
    required String hash,
  }) async {
    await _storage.write(key: _key(userId, 'salt'), value: salt);
    await _storage.write(key: _key(userId, 'hash'), value: hash);
    await _storage.write(key: _key(userId, 'enabled'), value: 'true');
  }

  Future<void> deletePin(String userId) async {
    await _storage.delete(key: _key(userId, 'salt'));
    await _storage.delete(key: _key(userId, 'hash'));
    await _storage.delete(key: _key(userId, 'enabled'));
    await _storage.delete(key: _key(userId, 'biometrics'));
  }

  Future<bool> isBiometricsEnabled(String userId) async {
    final value = await _storage.read(key: _key(userId, 'biometrics'));
    return value == 'true';
  }

  Future<void> setBiometricsEnabled(String userId, bool enabled) async {
    await _storage.write(
      key: _key(userId, 'biometrics'),
      value: enabled ? 'true' : 'false',
    );
  }

  Future<AutoLockTimeout> getTimeout(String userId) async {
    final value = await _storage.read(key: _key(userId, 'timeout'));
    return AutoLockTimeout.fromString(value);
  }

  Future<void> setTimeout(String userId, AutoLockTimeout timeout) async {
    await _storage.write(
      key: _key(userId, 'timeout'),
      value: timeout.toStorageString(),
    );
  }

  Future<bool> getBlockScreenshots(String userId) async {
    final value = await _storage.read(key: _key(userId, 'block_screenshots'));
    return value != 'false'; // Default to true
  }

  Future<void> setBlockScreenshots(String userId, bool block) async {
    await _storage.write(
      key: _key(userId, 'block_screenshots'),
      value: block ? 'true' : 'false',
    );
  }

  Future<int> getFailedAttempts(String userId) async {
    final value = await _storage.read(key: _key(userId, 'failed_attempts'));
    if (value == null) return 0;
    return int.tryParse(value) ?? 0;
  }

  Future<DateTime?> getLockoutUntil(String userId) async {
    final value = await _storage.read(key: _key(userId, 'lockout_until'));
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> saveFailureState({
    required String userId,
    required int attempts,
    DateTime? lockoutUntil,
  }) async {
    await _storage.write(
      key: _key(userId, 'failed_attempts'),
      value: attempts.toString(),
    );
    if (lockoutUntil != null) {
      await _storage.write(
        key: _key(userId, 'lockout_until'),
        value: lockoutUntil.toIso8601String(),
      );
    } else {
      await _storage.delete(key: _key(userId, 'lockout_until'));
    }
  }

  Future<void> clearFailureState(String userId) async {
    await _storage.delete(key: _key(userId, 'failed_attempts'));
    await _storage.delete(key: _key(userId, 'lockout_until'));
  }

  /// Wipes all App Lock data for [userId] (called on logout or account wipe).
  Future<void> clearAllUserData(String userId) async {
    await deletePin(userId);
    await clearFailureState(userId);
    await _storage.delete(key: _key(userId, 'timeout'));
    await _storage.delete(key: _key(userId, 'block_screenshots'));
  }
}
