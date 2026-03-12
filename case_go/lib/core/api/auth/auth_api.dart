import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

import 'auth.dart';

class AuthApiImpl implements AuthApi {
  final String baseUrl;
  final String usersBaseUrl;
  final http.Client _client;

  /// Callback для получения актуального access-токена.
  /// Возвращает String? — если null, Authorization-заголовок не добавляется.
  final String? Function() accessTokenProvider;

  static const Map<String, String> _publicHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> get _authHeaders {
    final token = accessTokenProvider();
    if (token == null || token.isEmpty) {
      // Логируем чтобы сразу видеть проблему
      dev.log('⚠️ accessTokenProvider вернул null — Authorization заголовок не будет добавлен!',
          name: 'AuthApi');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  AuthApiImpl({
    required this.baseUrl,
    required this.accessTokenProvider,
    String? usersBaseUrl,
    http.Client? client,
  })  : usersBaseUrl =
            usersBaseUrl ?? baseUrl.replaceFirst('/auth', '/users'),
        _client = client ?? http.Client();

  Uri _uri(String base, String path) => Uri.parse('$base$path');
  String _encode(Map<String, dynamic> body) => jsonEncode(body);

  Map<String, dynamic> _decode(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  void _logRequest(String method, String path, [Object? body]) {
    dev.log(
      '→ $method $path${body != null ? ' body=$body' : ''}',
      name: 'AuthApi',
    );
  }

  void _logResponse(http.Response response) {
    dev.log(
      '← ${response.statusCode} ${response.request?.url}\n  body: ${response.body}',
      name: 'AuthApi',
    );
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    _logResponse(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decode(response);
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  @override
  Future<Map<String, dynamic>> googleAuth(Map<String, dynamic> body) async {
    const path = '/auth/google';
    _logRequest('POST', path, body);
    final response = await _client.post(
      _uri(baseUrl, path),
      headers: _publicHeaders,
      body: _encode(body),
    );
    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    const path = '/register';
    _logRequest('POST', path, body);
    final response = await _client.post(
      _uri(baseUrl, path),
      headers: _publicHeaders,
      body: _encode(body),
    );
    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> obtainToken(Map<String, dynamic> body) async {
    const path = '/token';
    _logRequest('POST', path, body);
    // OAuth2PasswordRequestForm ждёт form-urlencoded
    final response = await _client.post(
      _uri(baseUrl, path),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: body.map((k, v) => MapEntry(k, v.toString())),
    );
    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> refreshToken(Map<String, dynamic> body) async {
    const path = '/refresh';
    _logRequest('POST', path);
    final response = await _client.post(
      _uri(baseUrl, path),
      headers: _publicHeaders,
      body: _encode(body),
    );
    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> getMe() async {
    const path = '/me';
    _logRequest('GET', 'users$path');

    // Явно логируем токен для отладки
    final token = accessTokenProvider();
    dev.log('getMe() token: ${token != null ? '${token.substring(0, 20)}...' : 'NULL'}',
        name: 'AuthApi');

    final response = await _client.get(
      _uri(usersBaseUrl, path),
      headers: _authHeaders,
    );
    return _handleResponse(response);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}