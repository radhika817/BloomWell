import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomwell/core/api/api_client.dart';
import 'package:bloomwell/core/api/api_exceptions.dart';
import 'package:bloomwell/core/storage/secure_token_storage.dart';
import 'package:bloomwell/features/auth/domain/entities/user_entity.dart';
import 'package:bloomwell/features/auth/domain/entities/auth_tokens.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  group('ApiClient Error Mapping Tests', () {
    final client = ApiClient();

    test('Maps 401 invalid credentials to InvalidCredentialsException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/v1/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/v1/auth/login'),
          statusCode: 401,
          data: {
            'code': 'INVALID_CREDENTIALS',
            'message': 'Invalid email or password.',
            'request_id': 'req-123',
          },
        ),
      );

      final exception = client.mapDioError(dioError);
      expect(exception, isA<InvalidCredentialsException>());
      expect(exception.message, contains('Invalid email or password'));
      expect(exception.requestId, equals('req-123'));
    });

    test('Maps 409 duplicate email to EmailAlreadyRegisteredException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/v1/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/v1/auth/register'),
          statusCode: 409,
          data: {
            'code': 'EMAIL_ALREADY_REGISTERED',
            'message': 'An account with this email address already exists.',
            'request_id': 'req-456',
          },
        ),
      );

      final exception = client.mapDioError(dioError);
      expect(exception, isA<EmailAlreadyRegisteredException>());
      expect(exception.message, contains('already exists'));
    });

    test('Maps 429 rate limit to RateLimitException with retryAfterSeconds',
        () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/v1/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/v1/auth/login'),
          statusCode: 429,
          headers: Headers.fromMap({
            'retry-after': ['45'],
          }),
          data: {
            'code': 'RATE_LIMITED',
            'message': 'Too many requests. Please wait before trying again.',
            'request_id': 'req-789',
          },
        ),
      );

      final exception = client.mapDioError(dioError);
      expect(exception, isA<RateLimitException>());
      final rateLimitEx = exception as RateLimitException;
      expect(rateLimitEx.retryAfterSeconds, equals(45));
    });

    test('Maps 422 to ValidationException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/v1/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/v1/auth/register'),
          statusCode: 422,
          data: {
            'code': 'VALIDATION_ERROR',
            'message': 'Invalid request parameters',
            'details': [
              {'msg': 'Password too short'}
            ],
          },
        ),
      );

      final exception = client.mapDioError(dioError);
      expect(exception, isA<ValidationException>());
    });

    test('Maps connection error to NetworkException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/v1/auth/login'),
        type: DioExceptionType.connectionTimeout,
      );

      final exception = client.mapDioError(dioError);
      expect(exception, isA<NetworkException>());
    });
  });

  group('Domain Entities Tests', () {
    test('UserEntity deserializes from API contract JSON', () {
      final json = {
        'id': 'u-1234',
        'display_name': 'Aarohi',
        'role': 'student',
        'language': 'en',
        'timezone': 'Asia/Kolkata',
        'created_at': '2026-10-18T10:00:00.000Z',
      };

      final user = UserEntity.fromJson(json);
      expect(user.id, equals('u-1234'));
      expect(user.displayName, equals('Aarohi'));
      expect(user.role, equals('student'));
      expect(user.language, equals('en'));
      expect(user.timezone, equals('Asia/Kolkata'));
    });

    test('AuthTokens deserializes from API contract JSON', () {
      final json = {
        'access_token': 'jwt.token.here',
        'refresh_token': 'opaque-refresh-token',
        'token_type': 'bearer',
        'expires_in': 900,
      };

      final tokens = AuthTokens.fromJson(json);
      expect(tokens.accessToken, equals('jwt.token.here'));
      expect(tokens.refreshToken, equals('opaque-refresh-token'));
      expect(tokens.expiresIn, equals(900));
    });
  });

  group('SecureTokenStorage Tests', () {
    test('Save, read, and delete refresh token', () async {
      final storage = SecureTokenStorage();
      await storage.saveRefreshToken('test-token-123');
      final retrieved = await storage.getRefreshToken();
      expect(retrieved, equals('test-token-123'));

      await storage.deleteRefreshToken();
      final afterDelete = await storage.getRefreshToken();
      expect(afterDelete, isNull);
    });
  });
}
