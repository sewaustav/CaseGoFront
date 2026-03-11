import 'package:case_go/core/api/api.dart';
import 'package:case_go/core/storage/storage.dart';

class HomeRepository {
  final AuthApi _api;
  final StorageService _storage;

  HomeRepository(this._api, this._storage);

  Future<Map<String, dynamic>?> checkAuth() async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;

    try {
      return await _api.getMe();
    } on Exception catch (e) {
      if (e.toString().contains('401')) {
        return await _handleRefreshToken();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<Map<String, dynamic>?> _handleRefreshToken() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null) return null;

    try {
      final response = await _api.refreshToken({'refresh': refresh});
      final newAccess = response['access'] as String;
      await _storage.setAccessToken(newAccess);
      return await _api.getMe();
    } catch (_) {
      await _storage.clearAll();
      return null;
    }
  }
}