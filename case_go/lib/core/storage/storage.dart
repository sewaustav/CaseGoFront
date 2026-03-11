import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final _secure = const FlutterSecureStorage();
  late final SharedPreferences _prefs;

  // Синхронный кеш токенов — нужен для accessTokenProvider в AuthApiImpl
  String? _cachedAccessToken;
  String? _cachedRefreshToken;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Прогреваем кеш при старте
    _cachedAccessToken = await _secure.read(key: 'accessToken');
    _cachedRefreshToken = await _secure.read(key: 'refreshToken');
  }

  // --- Access Token ---
  Future<void> setAccessToken(String token) async {
    _cachedAccessToken = token;
    await _secure.write(key: 'accessToken', value: token);
  }

  Future<String?> getAccessToken() async => _cachedAccessToken;

  /// Синхронное чтение — используй для accessTokenProvider
  String? get accessTokenSync => _cachedAccessToken;

  // --- Refresh Token ---
  Future<void> setRefreshToken(String token) async {
    _cachedRefreshToken = token;
    await _secure.write(key: 'refreshToken', value: token);
  }

  Future<String?> getRefreshToken() async => _cachedRefreshToken;

  String? get refreshTokenSync => _cachedRefreshToken;

  // --- Очистка ---
  Future<void> clearAll() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    await _secure.deleteAll();
    await _prefs.clear();
  }
}