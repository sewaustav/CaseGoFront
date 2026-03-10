part of 'auth_bloc.dart';

enum AuthMode { login, register }

sealed class AuthState {
  const AuthState();
}

/// Форма в режиме ожидания ввода.
final class AuthIdle extends AuthState {
  final AuthMode mode;
  const AuthIdle({this.mode = AuthMode.login});
}

/// Идёт сетевой запрос.
final class AuthLoading extends AuthState {
  final AuthMode mode;
  const AuthLoading({required this.mode});
}

/// Аутентификация прошла успешно.
final class AuthAuthenticated extends AuthState {
  final AuthUser user;
  const AuthAuthenticated({required this.user});
}

/// Произошла ошибка.
final class AuthError extends AuthState {
  final String message;
  final AuthMode mode;
  const AuthError({required this.message, required this.mode});
}