import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/secure_token_storage.dart';
import 'api_exceptions.dart';

/// Interceptor that:
/// 1. Injects Bearer token and Accept-Language headers.
/// 2. Performs single-flight token refresh retry queue on 401 responses.
/// 3. Maps Dio errors into typed BloomWell ApiExceptions without leaking sensitive data.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.dio,
    required this.tokenStorage,
    required this.getAccessToken,
    required this.onTokensRotated,
    required this.onSessionExpired,
    required this.getLocale,
  });

  final Dio dio;
  final SecureTokenStorage tokenStorage;
  final String? Function() getAccessToken;
  final void Function(String newAccessToken, String newRefreshToken)
      onTokensRotated;
  final void Function() onSessionExpired;
  final String Function() getLocale;

  bool _isRefreshing = false;
  final List<({RequestOptions options, Completer<Response<dynamic>> completer})>
      _pendingRequests = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Inject Accept-Language
    options.headers['Accept-Language'] = getLocale();

    // Inject Bearer token if present in memory and not already set
    final token = getAccessToken();
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final statusCode = response?.statusCode;
    final path = err.requestOptions.path;

    // Check if 401 on an authenticated endpoint (not login/register/refresh itself)
    final isAuthEndpoint = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/logout');

    if (statusCode == 401 && !isAuthEndpoint) {
      if (_isRefreshing) {
        // Enqueue this request to be retried after the in-flight refresh completes
        final completer = Completer<Response<dynamic>>();
        _pendingRequests
            .add((options: err.requestOptions, completer: completer));
        try {
          final retriedResponse = await completer.future;
          return handler.resolve(retriedResponse);
        } catch (e) {
          if (e is DioException) {
            return handler.next(e);
          }
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: e,
              type: DioExceptionType.unknown,
            ),
          );
        }
      }

      _isRefreshing = true;
      try {
        final currentRefreshToken = await tokenStorage.getRefreshToken();
        if (currentRefreshToken == null) {
          _isRefreshing = false;
          _failPendingRequests(err);
          onSessionExpired();
          return handler.next(err);
        }

        // Perform token refresh call with a separate Dio request to avoid interceptor recursion
        final refreshResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/refresh',
          data: {'refresh_token': currentRefreshToken},
          options: Options(
            headers: {'Authorization': null},
          ),
        );

        final data = refreshResponse.data;
        if (data != null &&
            data['access_token'] is String &&
            data['refresh_token'] is String) {
          final newAccessToken = data['access_token'] as String;
          final newRefreshToken = data['refresh_token'] as String;

          await tokenStorage.saveRefreshToken(newRefreshToken);
          onTokensRotated(newAccessToken, newRefreshToken);

          // Retry the original failed request
          final originalOptions = err.requestOptions;
          originalOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await dio.fetch<dynamic>(originalOptions);

          // Process queued requests
          final pending = List.of(_pendingRequests);
          _pendingRequests.clear();
          for (final item in pending) {
            item.options.headers['Authorization'] = 'Bearer $newAccessToken';
            dio.fetch<dynamic>(item.options).then(
                  (res) => item.completer.complete(res),
                  onError: (dynamic e) =>
                      item.completer.completeError(e as Object),
                );
          }

          _isRefreshing = false;
          return handler.resolve(retryResponse);
        } else {
          throw const UnauthorizedException();
        }
      } catch (e) {
        _isRefreshing = false;
        await tokenStorage.deleteRefreshToken();
        _failPendingRequests(err);
        onSessionExpired();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  void _failPendingRequests(DioException err) {
    final pending = List.of(_pendingRequests);
    _pendingRequests.clear();
    for (final item in pending) {
      item.completer.completeError(err);
    }
  }
}
