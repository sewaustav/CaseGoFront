import 'package:case_go/core/api/auth/auth.dart';
import 'package:case_go/core/api/auth/auth_api.dart';
import 'package:case_go/core/api/profile/profile.dart';
import 'package:case_go/core/storage/storage.dart';
import 'package:case_go/features/auth/models/auth_exception.dart';
import 'package:case_go/features/auth/models/auth_user.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final AuthApi _api;
  final ProfileApi _profileApi;
  final StorageService _storage;

  static const _webClientId =
      '507429813406-cp3kvojsh2vmp1d0j658m621pe0fp0ng.apps.googleusercontent.com';
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  AuthRepository({
    required AuthApi api,
    required ProfileApi profileApi,
    required StorageService storage,
  })  : _api = api,
        _profileApi = profileApi,
        _storage = storage;

  // ── Google init ───────────────────────────────────────────

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize(
      clientId: _webClientId,
      serverClientId: _webClientId,
    );
    _googleInitialized = true;
  }

  // ── Токены ────────────────────────────────────────────────

  String _extractAccessToken(Map<String, dynamic> data) {
    final token = data['access'] ?? data['access_token'];
    if (token == null) {
      throw AuthFailureException(
        'Сервер не вернул access-токен. Ключи: ${data.keys.toList()}',
      );
    }
    return token as String;
  }

  String _extractRefreshToken(Map<String, dynamic> data) {
    final token = data['refresh'] ?? data['refresh_token'];
    if (token == null) {
      throw AuthFailureException(
        'Сервер не вернул refresh-токен. Ключи: ${data.keys.toList()}',
      );
    }
    return token as String;
  }

  Future<void> _saveTokens(Map<String, dynamic> tokenData) async {
    await _storage.setAccessToken(_extractAccessToken(tokenData));
    await _storage.setRefreshToken(_extractRefreshToken(tokenData));
  }

  // ── Проверка наличия профиля ──────────────────────────────

  /// Проверяет, заполнен ли профиль пользователя на сервере.
  ///
  /// Возвращает true если профиль существует и активен.
  /// Возвращает false если сервер вернул 404 (профиль не заполнен).
  ///
  /// Примечание: бэкенд возвращает 404 + {"info": "user is not active"}
  /// когда профиль не существует — обрабатываем именно это.
  Future<bool> hasProfile() async {
    try {
      await _profileApi.getProfile();
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return false;
      // Бэкенд возвращает 500 + "no rows in result set" когда профиль не создан.
      // Это баг на бэкенде (должен быть 404), обрабатываем на клиенте.
      if (e.statusCode == 500 && e.message.contains('no rows in result set')) {
        return false;
      }
      debugPrint('hasProfile check error (${e.statusCode}): ${e.message}');
      return true;
    } catch (e) {
      debugPrint('hasProfile unexpected error: $e');
      return true;
    }
  }

  // ── Публичные методы ──────────────────────────────────────

  /// Вход по email + password.
  /// Возвращает пару (user, needsProfileSetup).
  Future<(AuthUser, bool)> login({
    required String email,
    required String password,
  }) async {
    try {
      final tokenData = await _api.obtainToken({
        'username': email,
        'password': password,
      });
      await _saveTokens(tokenData);
      final user = await _fetchMe();
      final profileExists = await hasProfile();
      return (user, !profileExists);
    } on AuthFailureException {
      rethrow;
    } on ApiException catch (e) {
      throw AuthFailureException(_mapApiError(e));
    } catch (e, st) {
      debugPrint('Login error: $e\n$st');
      throw AuthFailureException('Ошибка входа: $e');
    }
  }

  /// Регистрация по email + password.
  /// Всегда возвращает needsProfileSetup = true.
  Future<(AuthUser, bool)> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _api.register({
        'username': name,
        'email': email,
        'password': password,
      });
      final tokenData = await _api.obtainToken({
        'username': email,
        'password': password,
      });
      await _saveTokens(tokenData);
      final user = await _fetchMe();
      // После регистрации профиль точно не заполнен
      return (user, true);
    } on AuthFailureException {
      rethrow;
    } on ApiException catch (e) {
      throw AuthFailureException(_mapApiError(e));
    } catch (e, st) {
      debugPrint('Register error: $e\n$st');
      throw AuthFailureException('Ошибка регистрации: $e');
    }
  }

  /// Вход через Google.
  /// Проверяет наличие профиля — если нет, возвращает needsProfileSetup = true.
  Future<(AuthUser, bool)> loginWithGoogle() async {
    await _ensureGoogleInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const AuthFailureException(
        'Google Sign-In не поддерживается на этой платформе',
      );
    }

    late GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelledException();
      }
      throw AuthFailureException('Google Sign-In ошибка: ${e.description}');
    } catch (e) {
      throw AuthFailureException('Неизвестная ошибка Google Sign-In: $e');
    }

    final auth = await googleUser.authentication;
    final idToken = auth.idToken;

    if (idToken == null) {
      throw const AuthFailureException(
          'Не удалось получить id_token от Google');
    }

    try {
      final data = await _api.googleAuth({'id_token': idToken});
      await _saveTokens(data);

      AuthUser user;
      final userJson = data['user'];
      if (userJson is Map<String, dynamic>) {
        user = AuthUser.fromJson(userJson);
      } else {
        user = await _fetchMe();
      }

      final profileExists = await hasProfile();
      return (user, !profileExists);
    } on AuthFailureException {
      rethrow;
    } on ApiException catch (e) {
      throw AuthFailureException(_mapApiError(e));
    } catch (e, st) {
      debugPrint('Google login error: $e\n$st');
      throw AuthFailureException('Ошибка Google входа: $e');
    }
  }

  /// Восстанавливает сессию при старте приложения.
  /// Возвращает (user, needsProfileSetup) или null если токенов нет.
  Future<(AuthUser, bool)?> restoreSession() async {
    final access = await _storage.getAccessToken();
    if (access == null || access.isEmpty) return null;

    try {
      final user = await _fetchMe();
      final profileExists = await hasProfile();
      return (user, !profileExists);
    } on ApiException catch (e) {
      if (e.statusCode != 401) rethrow;
      return _tryRefresh();
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  // ── Приватные хелперы ─────────────────────────────────────

  Future<AuthUser> _fetchMe() async {
    final data = await _api.getMe();
    return AuthUser.fromJson(data);
  }

  Future<(AuthUser, bool)?> _tryRefresh() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null) return null;

    try {
      final data = await _api.refreshToken({'refresh': refresh});
      await _storage.setAccessToken(_extractAccessToken(data));
      final user = await _fetchMe();
      final profileExists = await hasProfile();
      return (user, !profileExists);
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