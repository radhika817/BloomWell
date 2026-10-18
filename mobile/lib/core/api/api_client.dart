import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_exceptions.dart';

/// Resolves the API base URL per BloomWell specification:
/// 1. Compile-time environment variable `API_BASE_URL`.
/// 2. If not specified:
///    - `http://10.0.2.2:8000` on Android emulator.
///    - `http://localhost:8000` on Web, iOS simulator, and Desktop.
String resolveBaseUrl() {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) {
    return envUrl;
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://localhost:8000';
}

/// Centralized API client wrapper around Dio.
class ApiClient {
  ApiClient({
    String? baseUrl,
    Dio? dio,
  }) : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? resolveBaseUrl(),
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  final Dio dio;

  /// Helper to map any DioException into a typed BloomWell ApiException.
  ApiException mapDioError(DioException error) {
    final response = error.response;
    if (response == null) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return const NetworkException();
      }
      return const ServerException(
          message: 'Network error or service unavailable');
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;
    String? code;
    String? message;
    String? requestId;
    dynamic details;

    if (data is Map<String, dynamic>) {
      code = data['code'] as String?;
      message = data['message'] as String?;
      requestId = data['request_id'] as String?;
      details = data['details'];
    }

    switch (statusCode) {
      case 401:
        if (code == 'INVALID_CREDENTIALS' ||
            (message != null &&
                message.toLowerCase().contains('invalid email or password'))) {
          return InvalidCredentialsException(
            message: message ?? 'Invalid email or password.',
            code: code,
            requestId: requestId,
          );
        }
        return UnauthorizedException(
          message: message ?? 'Unauthorized or session expired.',
          code: code,
          requestId: requestId,
        );
      case 409:
        return EmailAlreadyRegisteredException(
          message:
              message ?? 'An account with this email address already exists.',
          code: code,
          requestId: requestId,
        );
      case 422:
        return ValidationException(
          message: message ?? 'Invalid request parameters.',
          code: code,
          requestId: requestId,
          details: details,
        );
      case 429:
        int retryAfter = 60;
        final retryHeader = response.headers.value('retry-after');
        if (retryHeader != null) {
          retryAfter = int.tryParse(retryHeader) ?? 60;
        }
        return RateLimitException(
          retryAfterSeconds: retryAfter,
          message:
              message ?? 'Too many requests. Please wait before trying again.',
          code: code,
          requestId: requestId,
        );
      default:
        if (statusCode >= 500) {
          return ServerException(
            message:
                message ?? 'A server error occurred. Please try again later.',
            code: code,
            requestId: requestId,
            statusCode: statusCode,
          );
        }
        return ServerException(
          message: message ?? 'An unexpected error occurred.',
          code: code,
          requestId: requestId,
          statusCode: statusCode,
        );
    }
  }
}
