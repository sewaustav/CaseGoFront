import 'dart:async';

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
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authEventsSub;

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
    // На вебе `serverClientId` вызывает assert в debug и не используется в release.
    // На мобилке — нужен для получения idToken для бэкенда.
    if (kIsWeb) {
      await _googleSignIn.initialize(clientId: _webClientId);
    } else {
      await _googleSignIn.initialize(serverClientId: _webClientId);
    }
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

  Future<bool> hasProfile() async {
    try {
      await _profileApi.getProfile();
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return false;
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

  /// Подписка на Google auth events. Нужно вызвать один раз при старте
  /// на вебе — кнопка GIS может сработать в любой момент.
  Future<void> initGoogleAuthListener({
    required void Function(AuthUser user, bool needsProfileSetup) onSignIn,
    required void Function(String message) onError,
  }) async {
    await _ensureGoogleInitialized();

    _authEventsSub?.cancel();
    _authEventsSub = _googleSignIn.authenticationEvents.listen(
      (event) async {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          try {
            final result = await _handleGoogleUser(event.user);
            onSignIn(result.$1, result.$2);
          } catch (e) {
            if (e is AuthFailureException) {
              onError(e.message);
            } else {
              onError('Ошибка Google входа: $e');
            }
          }
        }
      },
      onError: (e) {
        onError('Google Sign-In ошибка: $e');
      },
    );

    // Пытаемся silent-auth (FedCM / One Tap) — если не залогинен, просто вернёт null.
    if (kIsWeb) {
      try {
        await _googleSignIn.attemptLightweightAuthentication();
      } catch (_) {
        // Silent flow может молча фейлиться — это ок.
      }
    }
  }

  /// Вход через Google. Для мобилок — открывает нативный выбор аккаунта.
  /// На вебе кидает ошибку — там должна использоваться Google-кнопка.
  Future<(AuthUser, bool)> loginWithGoogle() async {
    await _ensureGoogleInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const AuthFailureException(
        'На вебе используйте Google-кнопку для входа',
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

    return _handleGoogleUser(googleUser);
  }

  Future<(AuthUser, bool)> _handleGoogleUser(GoogleSignInAccount user) async {
    final auth = user.authentication;
    final idToken = auth.idToken;

    if (idToken == null) {
      throw const AuthFailureException(
          'Не удалось получить id_token от Google');
    }

    try {
      final data = await _api.googleAuth({'id_token': idToken});
      await _saveTokens(data);

      AuthUser authUser;
      final userJson = data['user'];
      if (userJson is Map<String, dynamic>) {
        authUser = AuthUser.fromJson(userJson);
      } else {
        authUser = await _fetchMe();
      }

      final profileExists = await hasProfile();
      return (authUser, !profileExists);
    } on AuthFailureException {
      rethrow;
    } on ApiException catch (e) {
      throw AuthFailureException(_mapApiError(e));
    } catch (e, st) {
      debugPrint('Google login error: $e\n$st');
      throw AuthFailureException('Ошибка Google входа: $e');
    }
  }

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

  Future<void> dispose() async {
    await _authEventsSub?.cancel();
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
