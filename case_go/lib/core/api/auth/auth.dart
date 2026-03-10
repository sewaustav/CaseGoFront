import 'dart:async';

/// Абстрактный класс, описывающий API аутентификации и управления сессией.
///
/// Покрывает следующие эндпоинты:
/// - POST /register
/// - POST /token
/// - POST /refresh
/// - GET  /me
abstract class AuthApi {
  /// Авторизует / регистрирует пользователя через Google OAuth.
  ///
  /// [body] — объект с полем `id_token` (Google ID Token).
  /// Возвращает объект с `access`, `refresh` токенами и данными пользователя.
  Future<Map<String, dynamic>> googleAuth(Map<String, dynamic> body);

  /// Регистрирует нового пользователя.
  ///
  /// [body] — данные пользователя (имя, email, пароль и т.д.).
  /// Возвращает данные созданного пользователя.
  Future<Map<String, dynamic>> register(Map<String, dynamic> body);

  /// Получает JWT-токен (логин).
  ///
  /// [body] — учётные данные (например, email + password).
  /// Возвращает объект с `access` и `refresh` токенами.
  Future<Map<String, dynamic>> obtainToken(Map<String, dynamic> body);

  /// Обновляет access-токен с помощью refresh-токена.
  ///
  /// [body] — объект с полем `refresh`.
  /// Возвращает новый `access` токен.
  Future<Map<String, dynamic>> refreshToken(Map<String, dynamic> body);

  /// Возвращает данные текущего авторизованного пользователя.
  ///
  /// Требует валидный Bearer-токен в заголовке запроса.
  Future<Map<String, dynamic>> getMe();
}