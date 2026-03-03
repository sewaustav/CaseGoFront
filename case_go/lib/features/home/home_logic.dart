import 'package:case_go/core/api/api.dart';
import 'package:case_go/core/storage/storage.dart';

class HomeRepository {
  final AuthApi _api;
  final StorageService _storage;

  HomeRepository(this._api, this._storage);

  /// Основной метод проверки авторизации
  Future<Map<String, dynamic>?> checkAuth() async {
    // 1. Проверяем наличие токена в хранилище
    final token = await _storage.getAccessToken();
    if (token == null) return null; // Сразу на выход (на экран логина)

    try {
      // 2. Пытаемся получить профиль
      return await _api.getMe();
    } on Exception catch (e) {
      // Проверяем, не ошибка ли это авторизации (401)
      // В твоем ApiException это statusCode == 401
      if (e.toString().contains('401')) {
        return await _handleRefreshToken();
      }
      rethrow;
    }
  }

  /// Вспомогательный метод обновления токена
  Future<Map<String, dynamic>?> _handleRefreshToken() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null) return null;

    try {
      // 3. Пытаемся обновить токен
      final response = await _api.refreshToken({'refresh': refresh});
      final newAccess = response['access'];

      // Сохраняем новый токен
      await _storage.setAccessToken(newAccess);

      // 4. Повторный запрос профиля с новым токеном
      return await _api.getMe();
    } catch (_) {
      // Если даже рефреш не помог — чистим всё и выходим
      await _storage.clearAll();
      return null;
    }
  }
}