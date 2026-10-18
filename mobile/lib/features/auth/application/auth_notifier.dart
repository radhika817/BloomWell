import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/api/auth_interceptor.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/entities/auth_state.dart';

/// Provider for secure storage of refresh tokens.
final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

/// Provider for the centralized ApiClient with AuthInterceptor attached.
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureTokenStorageProvider);
  final client = ApiClient();

  final interceptor = AuthInterceptor(
    dio: client.dio,
    tokenStorage: storage,
    getAccessToken: () => ref.read(authNotifierProvider).accessToken,
    onTokensRotated: (newAccess, newRefresh) {
      ref.read(authNotifierProvider.notifier).updateAccessToken(newAccess);
    },
    onSessionExpired: () {
      ref.read(authNotifierProvider.notifier).handleSessionExpired();
    },
    getLocale: () => 'en',
  );

  client.dio.interceptors.add(interceptor);
  return client;
});

/// Provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient: apiClient);
});

/// Controller and state manager for authentication.
class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;
  late final SecureTokenStorage _tokenStorage;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _tokenStorage = ref.watch(secureTokenStorageProvider);
    return const AuthState.initial();
  }

  /// Restores session on app startup if a refresh token is present.
  Future<void> restoreSession() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    state = const AuthState.authenticating();
    try {
      final tokens = await _repository.refresh(refreshToken: refreshToken);
      await _tokenStorage.saveRefreshToken(tokens.refreshToken);
      final user = await _repository.getMe(accessToken: tokens.accessToken);
      state =
          AuthState.authenticated(user: user, accessToken: tokens.accessToken);
    } catch (_) {
      await _tokenStorage.deleteRefreshToken();
      state = const AuthState.unauthenticated();
    }
  }

  /// Registers a new student account.
  Future<bool> register({
    required String email,
    required String password,
    required String timezone,
    String? displayName,
  }) async {
    state = const AuthState.authenticating();
    try {
      final result = await _repository.register(
        email: email,
        password: password,
        timezone: timezone,
        displayName: displayName,
      );
      await _tokenStorage.saveRefreshToken(result.tokens.refreshToken);
      state = AuthState.authenticated(
        user: result.user,
        accessToken: result.tokens.accessToken,
      );
      return true;
    } on ApiException catch (e) {
      if (e is RateLimitException) {
        state = AuthState.unauthenticated(
          errorMessage: e.message,
          rateLimitSeconds: e.retryAfterSeconds,
        );
      } else {
        state = AuthState.unauthenticated(errorMessage: e.message);
      }
      return false;
    } catch (e) {
      state = const AuthState.unauthenticated(
        errorMessage:
            'Something went wrong. Please check your connection and try again.',
      );
      return false;
    }
  }

  /// Logs in an existing student account.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState.authenticating();
    try {
      final result = await _repository.login(email: email, password: password);
      await _tokenStorage.saveRefreshToken(result.tokens.refreshToken);
      state = AuthState.authenticated(
        user: result.user,
        accessToken: result.tokens.accessToken,
      );
      return true;
    } on ApiException catch (e) {
      if (e is RateLimitException) {
        state = AuthState.unauthenticated(
          errorMessage: e.message,
          rateLimitSeconds: e.retryAfterSeconds,
        );
      } else {
        state = AuthState.unauthenticated(errorMessage: e.message);
      }
      return false;
    } catch (e) {
      state = const AuthState.unauthenticated(
        errorMessage:
            'Something went wrong. Please check your connection and try again.',
      );
      return false;
    }
  }

  /// Logs out, revokes server refresh token family, and clears local tokens.
  Future<void> logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _repository.logout(refreshToken: refreshToken);
      } catch (_) {
        // Ignored; logout is idempotent
      }
    }
    await _tokenStorage.deleteRefreshToken();
    state = const AuthState.unauthenticated();
  }

  /// Updates in-memory access token on refresh rotation.
  void updateAccessToken(String newAccessToken) {
    if (state.user != null) {
      state = AuthState.authenticated(
        user: state.user!,
        accessToken: newAccessToken,
      );
    }
  }

  /// Called by AuthInterceptor when refresh fails.
  void handleSessionExpired() {
    state = const AuthState.unauthenticated();
  }

  /// Clears any transient error message.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null, rateLimitSeconds: null);
    }
  }
}

/// Main auth state provider.
final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
