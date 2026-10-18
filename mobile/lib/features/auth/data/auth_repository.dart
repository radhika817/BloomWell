import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../domain/entities/auth_tokens.dart';
import '../domain/entities/user_entity.dart';

/// Repository handling authentication API requests.
class AuthRepository {
  const AuthRepository({required this.apiClient});

  final ApiClient apiClient;

  /// Registers a new user. Returns issued tokens and initial profile.
  Future<({AuthTokens tokens, UserEntity user})> register({
    required String email,
    required String password,
    required String timezone,
    String? displayName,
  }) async {
    try {
      final payload = <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'password': password,
        'timezone': timezone,
      };
      if (displayName != null && displayName.trim().isNotEmpty) {
        payload['display_name'] = displayName.trim();
      }

      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/v1/auth/register',
        data: payload,
      );

      final data = response.data!;
      final tokens =
          AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>);
      final user = UserEntity.fromJson(data['user'] as Map<String, dynamic>);

      return (tokens: tokens, user: user);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  /// Logs in an existing user and fetches their profile.
  Future<({AuthTokens tokens, UserEntity user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/v1/auth/login',
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final tokens = AuthTokens.fromJson(response.data!);
      final user = await getMe(accessToken: tokens.accessToken);

      return (tokens: tokens, user: user);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  /// Rotates the refresh token and returns new tokens.
  Future<AuthTokens> refresh({required String refreshToken}) async {
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Authorization': null},
        ),
      );

      return AuthTokens.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  /// Logs out by revoking the refresh token family on the server.
  Future<void> logout({required String refreshToken}) async {
    try {
      await apiClient.dio.post<void>(
        '/v1/auth/logout',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Authorization': null},
        ),
      );
    } on DioException catch (e) {
      // Logout is idempotent; log nothing and ignore or map
      throw apiClient.mapDioError(e);
    }
  }

  /// Fetches the authenticated user's profile.
  Future<UserEntity> getMe({required String accessToken}) async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/me',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      return UserEntity.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }
}
