import 'package:case_go/core/api/auth/auth.dart';
import 'package:case_go/core/api/auth/auth_api.dart';
import 'package:case_go/core/storage/storage.dart';
import 'package:case_go/features/auth/models/auth_exception.dart';
import 'package:case_go/features/auth/models/auth_user.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final AuthApi _api;
  final StorageService _storage;
  static const _webClientId = '507429813406-968aiglclt851uq61tvrse55b16889h1.apps.googleusercontent.com';
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
    await _googleSignIn.initialize(
      serverClientId: _webClientId,
    );
    _googleInitialized = true;
  }

  // ── Токены ────────────────────────────────────────────────

  /// Извлекает access-токен из ответа сервера.
  /// Поддерживает оба варианта именования: 'access' и 'access_token'.
  String _extractAccessToken(Map<String, dynamic> data) {
    final token = data['access'] ?? data['access_token'];
    if (token == null) {
      throw AuthFailureException(
        'Сервер не вернул access-токен. Ключи в ответе: ${data.keys.toList()}',
      );
    }
    return token as String;
  }

  /// Извлекает refresh-токен из ответа сервера.
  /// Поддерживает оба варианта именования: 'refresh' и 'refresh_token'.
  String _extractRefreshToken(Map<String, dynamic> data) {
    final token = data['refresh'] ?? data['refresh_token'];
    if (token == null) {
      throw AuthFailureException(
        'Сервер не вернул refresh-токен. Ключи в ответе: ${data.keys.toList()}',
      );
    }
    return token as String;
  }

  Future<void> _saveTokens(Map<String, dynamic> tokenData) async {
    await _storage.setAccessToken(_extractAccessToken(tokenData));
    await _storage.setRefreshToken(_extractRefreshToken(tokenData));
  }

  // ── Публичные методы ──────────────────────────────────────

  /// Вход по email + password.
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final tokenData = await _api.obtainToken({
        'username': email,
        'password': password,
      });
      debugPrint('Login token response keys: ${tokenData.keys.toList()}');
      await _saveTokens(tokenData);
      return _fetchMe();
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
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Шаг 1: регистрация — бэкенд возвращает UserResponse (без токенов)
      final registerData = await _api.register({
        'username': name,
        'email': email,
        'password': password,
      });
      debugPrint('Register response keys: ${registerData.keys.toList()}');

      // Шаг 2: логин — получаем токены
      final tokenData = await _api.obtainToken({
        'username': email,
        'password': password,
      });
      debugPrint('Token response keys: ${tokenData.keys.toList()}');

      await _saveTokens(tokenData);
      return _fetchMe();
    } on AuthFailureException {
      rethrow;
    } on ApiException catch (e) {
      throw AuthFailureException(_mapApiError(e));
    } catch (e, st) {
      debugPrint('Register error: $e\n$st');
      throw AuthFailureException('Ошибка регистрации: $e');
    }
  }

  Future<AuthUser> loginWithGoogle() async {
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

    // В v7.x idToken живёт здесь, а не в authorizationClient
    final auth = await googleUser.authentication;
    final idToken = auth.idToken;

    debugPrint('Google idToken: ${idToken != null ? '${idToken.substring(0, 20)}...' : 'NULL'}');

    if (idToken == null) {
      throw const AuthFailureException('Не удалось получить id_token от Google');
    }

    try {
      final data = await _api.googleAuth({'id_token': idToken});
      debugPrint('Google auth response keys: ${data.keys.toList()}');
      await _saveTokens(data);

      final userJson = data['user'];
      if (userJson is Map<String, dynamic>) {
        return AuthUser.fromJson(userJson);
      }
      return _fetchMe();
    } on AuthFailureException {
      rethrow;
    } on ApiException catch (e) {
      throw AuthFailureException(_mapApiError(e));
    } catch (e, st) {
      debugPrint('Google login error: $e\n$st');
      throw AuthFailureException('Ошибка Google входа: $e');
    }
  }

  /// Восстанавливает сессию при старте.
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
    } catch (_) {}
  }

  // ── Приватные хелперы ─────────────────────────────────────

  Future<AuthUser> _fetchMe() async {
    final data = await _api.getMe();
    debugPrint('getMe response: $data');
    return AuthUser.fromJson(data);
  }

  Future<AuthUser?> _tryRefresh() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null) return null;

    try {
      final data = await _api.refreshToken({'refresh': refresh});
      await _storage.setAccessToken(_extractAccessToken(data));
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

