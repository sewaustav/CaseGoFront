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
/// [needsProfileSetup] = true → профиль не заполнен → редирект на /profile/setup.
/// Работает для логина, регистрации и Google Sign-In одинаково.
final class AuthAuthenticated extends AuthState {
  final AuthUser user;
  final bool needsProfileSetup;

  const AuthAuthenticated({
    required this.user,
    this.needsProfileSetup = false,
  });
}

final class AuthError extends AuthState {
  final String message;
  final AuthMode mode;
  const AuthError({required this.message, required this.mode});
}