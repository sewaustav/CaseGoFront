import 'package:case_go/core/api/auth/auth.dart';
import 'package:case_go/core/api/auth/auth_api.dart';
import 'package:case_go/core/storage/storage.dart';
import 'package:case_go/features/auth/models/auth_exception.dart';
import 'package:case_go/features/auth/models/auth_user.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Репозиторий аутентификации.
///
/// Совместим с google_sign_in ^7.0 — новый singleton API:
///   GoogleSignIn.instance  вместо  GoogleSignIn()
///   .authenticate()        вместо  .signIn()
///   .signOut()             не изменился
class AuthRepository {
  final AuthApi _api;
  final StorageService _storage;

  // v7: singleton, не создаём через конструктор
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  AuthRepository({
    required AuthApi api,
    required StorageService storage,
  })  : _api = api,
        _storage = storage;

  // ── Инициализация Google ──────────────────────────────────

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  // ── Токены ────────────────────────────────────────────────

  Future<void> _saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.setAccessToken(access);
    await _storage.setRefreshToken(refresh);
  }

  // ── Публичные методы ──────────────────────────────────────

  /// Вход по email + password.
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final data =
          await _api.obtainToken({'email': email, 'password': password});
      await _saveTokens(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
      );
      return _fetchMe();
    } on ApiException catch (e) {
      throw AuthFailureException(_mapApiError(e));
    }
  }

  /// Регистрация по email + password.
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final data = await _api.register({
        'username': name,
        'email': email,
        'password': password,
      });
      await _saveTokens(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
      );
      return _fetchMe();
    } on ApiException catch (e) {
      throw AuthFailureException(_mapApiError(e));
    }
  }

  /// Вход через Google (google_sign_in ^7.0).
  Future<AuthUser> loginWithGoogle() async {
    await _ensureGoogleInitialized();

    // v7: supportsAuthenticate() — проверяем поддержку платформы
    if (!_googleSignIn.supportsAuthenticate()) {
      throw const AuthFailureException(
        'Google Sign-In не поддерживается на этой платформе',
      );
    }

    late GoogleSignInAccount googleUser;
    try {
      // v7: authenticate() вместо signIn()
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelledException();
      }
      throw AuthFailureException('Google Sign-In ошибка: ${e.description}');
    } catch (e) {
      throw AuthFailureException('Неизвестная ошибка Google Sign-In: $e');
    }

    // v7: ID-токен получаем через authorizationClient
    // Нам нужен serverClientId для получения idToken на мобильных платформах.
    // Если бэкенд принимает accessToken — используй его.
    // Здесь показан вариант с accessToken (более универсальный для v7).
    final authorization = await googleUser.authorizationClient
        .authorizationForScopes(['email', 'profile']);

    if (authorization == null) {
      throw const AuthFailureException('Не удалось получить токен Google');
    }

    final accessToken = authorization.accessToken;

    try {
      // Отправляем accessToken на бэкенд (поменяй ключ если бэкенд ждёт id_token)
      final data = await _api.googleAuth({'access_token': accessToken});
      await _saveTokens(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
      );
      final userJson = data['user'];
      if (userJson is Map<String, dynamic>) {
        return AuthUser.fromJson(userJson);
      }
      return _fetchMe();
    } on ApiException catch (e) {
      throw AuthFailureException(_mapApiError(e));
    }
  }

  /// Восстанавливает сессию при старте. Возвращает `null`, если токена нет.
  Future<AuthUser?> restoreSession() async {
    final access = await _storage.getAccessToken();
    if (access == null || access.isEmpty) return null;

    try {
      return await _fetchMe();
    } on ApiException catch (e) {
      if (e.statusCode != 401) rethrow;
      return _tryRefresh();
    }
  }

  /// Выход.
  Future<void> logout() async {
    await _storage.clearAll();
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Игнорируем ошибки Google при логауте
    }
  }

  // ── Приватные хелперы ─────────────────────────────────────

  Future<AuthUser> _fetchMe() async {
    final data = await _api.getMe();
    return AuthUser.fromJson(data);
  }

  Future<AuthUser?> _tryRefresh() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null) return null;

    try {
      final data = await _api.refreshToken({'refresh': refresh});
      await _storage.setAccessToken(data['access'] as String);
      return _fetchMe();
    } on ApiException {
      await _storage.clearAll();
      return null;
    }
  }

  String _mapApiError(ApiException e) => switch (e.statusCode) {
        400 => 'Неверные данные',
        401 => 'Неверный email или пароль',
        409 => 'Пользователь с таким email уже существует',
        422 => 'Проверьте правильность введённых данных',
        500 => 'Ошибка сервера. Попробуйте позже',
        _ => 'Что-то пошло не так (${e.statusCode})',
      };
}