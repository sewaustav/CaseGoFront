part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

/// Вход по email + password.
final class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted({required this.email, required this.password});
}

/// Регистрация по email + password.
final class RegisterSubmitted extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const RegisterSubmitted({
    required this.name,
    required this.email,
    required this.password,
  });
}

/// Вход через Google.
final class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

/// Пришёл результат авторизации из Google auth stream (веб через GIS button).
final class GoogleStreamAuthenticated extends AuthEvent {
  final AuthUser user;
  final bool needsProfileSetup;
  const GoogleStreamAuthenticated({
    required this.user,
    required this.needsProfileSetup,
  });
}

/// Ошибка из Google auth stream.
final class GoogleStreamErrored extends AuthEvent {
  final String message;
  const GoogleStreamErrored(this.message);
}

/// Переключение между формами логина и регистрации.
final class AuthModeToggled extends AuthEvent {
  const AuthModeToggled();
}