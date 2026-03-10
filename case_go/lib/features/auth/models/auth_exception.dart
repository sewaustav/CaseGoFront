/// Базовое исключение auth-модуля.
sealed class AuthException implements Exception {
  const AuthException();
}

/// Пользователь отменил вход (Google Sign-In dismissed).
class AuthCancelledException extends AuthException {
  const AuthCancelledException();

  @override
  String toString() => 'AuthCancelledException';
}

/// Любая другая ошибка аутентификации.
class AuthFailureException extends AuthException {
  final String message;
  const AuthFailureException(this.message);

  @override
  String toString() => 'AuthFailureException: $message';
}