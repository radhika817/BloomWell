import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token storage for persisting the refresh token.
/// Per BloomWell architecture rules:
/// - Access token is kept strictly in-memory (never persisted).
/// - Refresh token is persisted in FlutterSecureStorage on Android/iOS/Desktop.
/// - On web (kIsWeb), refresh token is kept in-memory to prevent localStorage leaks.
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
            );

  final FlutterSecureStorage _storage;
  static const String _refreshTokenKey = 'bloomwell_refresh_token';
  String? _inMemoryWebRefreshToken;

  /// Stores the refresh token securely.
  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      _inMemoryWebRefreshToken = token;
      return;
    }
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Retrieves the stored refresh token, if any.
  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      return _inMemoryWebRefreshToken;
    }
    return _storage.read(key: _refreshTokenKey);
  }

  /// Deletes the stored refresh token.
  Future<void> deleteRefreshToken() async {
    if (kIsWeb) {
      _inMemoryWebRefreshToken = null;
      return;
    }
    await _storage.delete(key: _refreshTokenKey);
  }
}
