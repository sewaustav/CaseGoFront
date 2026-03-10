import 'package:case_go/core/api/auth/auth.dart';
import 'package:case_go/core/api/auth/auth_api.dart';
import 'package:case_go/core/storage/storage.dart';
import 'package:case_go/features/auth/models/auth_exception.dart';
import 'package:case_go/features/auth/models/auth_user.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Репозиторий аутентификации.
///
/// Зависит только от [AuthApi] и [StorageService] — оба передаются снаружи.
/// Токены хранятся в [StorageService]; в HTTP-заголовки они не прокидываются
/// отсюда — это зона [AuthApiImpl] или интерцептора.
class AuthRepository {
  final AuthApi _api;
  final StorageService _storage;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required AuthApi api,
    required StorageService storage,
    GoogleSignIn? googleSignIn,
  })  : _api = api,
        _storage = storage,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

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
        'name': name,
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

  /// Вход / регистрация через Google.
  Future<AuthUser> loginWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw const AuthCancelledException();

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const AuthFailureException('Не удалось получить Google ID Token');
    }

    try {
      final data = await _api.googleAuth({'id_token': idToken});
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

  /// Выход: чистим токены и Google-сессию.
  Future<void> logout() async {
    await _storage.clearAll();
    await _googleSignIn.signOut();
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