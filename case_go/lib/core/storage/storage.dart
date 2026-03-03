import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final _secure = const FlutterSecureStorage();
  late final SharedPreferences _prefs;

  // Инициализация (вызовем один раз в main)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- JWT (Secure) ---
  Future<void> setAccessToken(String token) => _secure.write(key: 'accessToken', value: token);
  Future<String?> getAccessToken() => _secure.read(key: 'accessToken');

  Future<void> setRefreshToken(String token) => _secure.write(key: 'refreshToken', value: token);
  Future<String?> getRefreshToken() => _secure.read(key: 'refreshToken');

  // --- Profile & Data (Future) ---


  // Очистка при выходе
  Future<void> clearAll() async {
    await _secure.deleteAll();
    await _prefs.clear();
  }
}