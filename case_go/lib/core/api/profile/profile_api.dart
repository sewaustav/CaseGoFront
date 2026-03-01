import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:case_go/core/api/profile/profile.dart';
import 'package:http/http.dart' as http;
import '../auth/auth_api.dart' show ApiException;

/// Базовая реализация [ProfileApi].
///
/// Все методы требуют авторизации — Bearer-токен передаётся
/// через [accessTokenProvider].
class ProfileApiImpl implements ProfileApi {
  // ──────────────────────────────────────────
  // Конфигурация
  // ──────────────────────────────────────────

  final String baseUrl;
  final http.Client _client;

  /// Callback, возвращающий актуальный access-токен.
  final String Function() accessTokenProvider;

  ProfileApiImpl({
    required this.baseUrl,
    required this.accessTokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  // ──────────────────────────────────────────
  // Вспомогательные методы
  // ──────────────────────────────────────────

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$baseUrl$path');
    return queryParams != null ? uri.replace(queryParameters: queryParams) : uri;
  }

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${accessTokenProvider()}',
      };

  String _encode(Map<String, dynamic> body) => jsonEncode(body);

  Map<String, dynamic> _decodeObject(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  List<Map<String, dynamic>> _decodeList(http.Response response) =>
      (jsonDecode(response.body) as List)
          .cast<Map<String, dynamic>>();

  void _logRequest(String method, String path, [Object? body]) {
    dev.log(
      '→ $method $path${body != null ? ' body=$body' : ''}',
      name: 'ProfileApi',
    );
  }

  void _logResponse(http.Response response) {
    dev.log(
      '← ${response.statusCode} ${response.request?.url}',
      name: 'ProfileApi',
    );
  }

  Map<String, dynamic> _handleObject(http.Response response) {
    _logResponse(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeObject(response);
    }
    throw ApiException(statusCode: response.statusCode, message: response.body);
  }

  List<Map<String, dynamic>> _handleList(http.Response response) {
    _logResponse(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeList(response);
    }
    throw ApiException(statusCode: response.statusCode, message: response.body);
  }

  void _handleEmpty(http.Response response) {
    _logResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(statusCode: response.statusCode, message: response.body);
    }
  }

  // ──────────────────────────────────────────
  // Профиль
  // ──────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> createProfile(Map<String, dynamic> body) async {
    _logRequest('POST', '/profile', body);
    final response = await _client.post(
      _uri('/profile'),
      headers: _authHeaders,
      body: _encode(body),
    );
    return _handleObject(response);
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    _logRequest('GET', '/profile');
    final response = await _client.get(_uri('/profile'), headers: _authHeaders);
    return _handleObject(response);
  }

  @override
  Future<Map<String, dynamic>> replaceProfile(Map<String, dynamic> body) async {
    _logRequest('PUT', '/profile', body);
    final response = await _client.put(
      _uri('/profile'),
      headers: _authHeaders,
      body: _encode(body),
    );
    return _handleObject(response);
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    _logRequest('PATCH', '/profile', body);
    final request = http.Request('PATCH', _uri('/profile'))
      ..headers.addAll(_authHeaders)
      ..body = _encode(body);
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    return _handleObject(response);
  }

  @override
  Future<void> deleteProfile() async {
    _logRequest('DELETE', '/profile');
    final response = await _client.delete(_uri('/profile'), headers: _authHeaders);
    _handleEmpty(response);
  }

  // ──────────────────────────────────────────
  // Социальные ссылки
  // ──────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> createSocialLink(Map<String, dynamic> body) async {
    _logRequest('POST', '/social', body);
    final response = await _client.post(
      _uri('/social'),
      headers: _authHeaders,
      body: _encode(body),
    );
    return _handleObject(response);
  }

  @override
  Future<Map<String, dynamic>> replaceSocialLink(
    int id,
    Map<String, dynamic> body,
  ) async {
    _logRequest('PUT', '/social/$id', body);
    final response = await _client.put(
      _uri('/social/$id'),
      headers: _authHeaders,
      body: _encode(body),
    );
    return _handleObject(response);
  }

  @override
  Future<void> deleteSocialLink(int id) async {
    _logRequest('DELETE', '/social/$id');
    final response = await _client.delete(
      _uri('/social/$id'),
      headers: _authHeaders,
    );
    _handleEmpty(response);
  }

  // ──────────────────────────────────────────
  // Цели пользователя
  // ──────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> createPurpose(Map<String, dynamic> body) async {
    _logRequest('POST', '/purpose', body);
    final response = await _client.post(
      _uri('/purpose'),
      headers: _authHeaders,
      body: _encode(body),
    );
    return _handleObject(response);
  }

  @override
  Future<Map<String, dynamic>> replacePurpose(
    int id,
    Map<String, dynamic> body,
  ) async {
    _logRequest('PUT', '/purpose/$id', body);
    final response = await _client.put(
      _uri('/purpose/$id'),
      headers: _authHeaders,
      body: _encode(body),
    );
    return _handleObject(response);
  }

  @override
  Future<void> deletePurpose(int id) async {
    _logRequest('DELETE', '/purpose/$id');
    final response = await _client.delete(
      _uri('/purpose/$id'),
      headers: _authHeaders,
    );
    _handleEmpty(response);
  }

  // ──────────────────────────────────────────
  // Профессии
  // ──────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> createProfession(Map<String, dynamic> body) async {
    _logRequest('POST', '/profession', body);
    final response = await _client.post(
      _uri('/profession'),
      headers: _authHeaders,
      body: _encode(body),
    );
    return _handleObject(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getProfessions() async {
    _logRequest('GET', '/profession');
    final response = await _client.get(_uri('/profession'), headers: _authHeaders);
    return _handleList(response);
  }

  @override
  Future<Map<String, dynamic>> replaceProfession(
    int id,
    Map<String, dynamic> body,
  ) async {
    _logRequest('PUT', '/profession/$id', body);
    final response = await _client.put(
      _uri('/profession/$id'),
      headers: _authHeaders,
      body: _encode(body),
    );
    return _handleObject(response);
  }

  @override
  Future<void> deleteProfession(int id) async {
    _logRequest('DELETE', '/profession/$id');
    final response = await _client.delete(
      _uri('/profession/$id'),
      headers: _authHeaders,
    );
    _handleEmpty(response);
  }

  // ──────────────────────────────────────────
  // Категории профессий
  // ──────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getProfessionCategories() async {
    _logRequest('GET', '/profession_categories');
    final response = await _client.get(
      _uri('/profession_categories'),
      headers: _authHeaders,
    );
    return _handleList(response);
  }

  // ──────────────────────────────────────────
  // Поиск
  // ──────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> search(
    Map<String, String> queryParams,
  ) async {
    _logRequest('GET', '/search', queryParams);
    final response = await _client.get(
      _uri('/search', queryParams),
      headers: _authHeaders,
    );
    return _handleList(response);
  }

  @override
  Future<List<Map<String, dynamic>>> searchByFio(String fio) async {
    _logRequest('GET', '/search/fio');
    final response = await _client.get(
      _uri('/search/fio', {'fio': fio}),
      headers: _authHeaders,
    );
    return _handleList(response);
  }
}