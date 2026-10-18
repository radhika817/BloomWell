import 'user_entity.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
}

/// Immutable authentication state held in Riverpod memory.
/// Per Rule 8: Access tokens and sensitive profile data remain in-memory only.
class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.accessToken,
    this.errorMessage,
    this.rateLimitSeconds,
  });

  final AuthStatus status;
  final UserEntity? user;
  final String? accessToken;
  final String? errorMessage;
  final int? rateLimitSeconds;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isAuthenticating => status == AuthStatus.authenticating;

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        accessToken = null,
        errorMessage = null,
        rateLimitSeconds = null;

  const AuthState.unauthenticated({this.errorMessage, this.rateLimitSeconds})
      : status = AuthStatus.unauthenticated,
        user = null,
        accessToken = null;

  const AuthState.authenticating()
      : status = AuthStatus.authenticating,
        user = null,
        accessToken = null,
        errorMessage = null,
        rateLimitSeconds = null;

  const AuthState.authenticated({
    required this.user,
    required this.accessToken,
  })  : status = AuthStatus.authenticated,
        errorMessage = null,
        rateLimitSeconds = null;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? accessToken,
    String? errorMessage,
    int? rateLimitSeconds,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      errorMessage: errorMessage,
      rateLimitSeconds: rateLimitSeconds,
    );
  }
}
