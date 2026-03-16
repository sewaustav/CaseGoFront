part of 'auth_bloc.dart';

enum AuthMode { login, register }

sealed class AuthState {
  const AuthState();
}

final class AuthIdle extends AuthState {
  final AuthMode mode;
  const AuthIdle({this.mode = AuthMode.login});
}

final class AuthLoading extends AuthState {
  final AuthMode mode;
  const AuthLoading({required this.mode});
}

/// Аутентификация прошла успешно.
///
/// [isNewUser] = true → только что зарегистрировался → ведём на /profile/setup
/// [isNewUser] = false → вошёл в существующий аккаунт → ведём на главную
final class AuthAuthenticated extends AuthState {
  final AuthUser user;
  final bool isNewUser;

  const AuthAuthenticated({required this.user, this.isNewUser = false});
}

final class AuthError extends AuthState {
  final String message;
  final AuthMode mode;
  const AuthError({required this.message, required this.mode});
}