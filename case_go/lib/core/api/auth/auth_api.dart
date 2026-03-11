import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

import 'auth.dart';

class AuthApiImpl implements AuthApi {
  final String baseUrl;
  final http.Client _client;

  /// Callback для получения актуального access-токена.
  /// Передай его если хочешь использовать getMe() — иначе оставь null
  /// и передавай токен вручную (не рекомендуется).
  final String? Function()? accessTokenProvider;

  static const Map<String, String> _publicHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> get _authHeaders {
    final token = accessTokenProvider?.call();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  AuthApiImpl({
    required this.baseUrl,
    this.accessTokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');
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
      '← ${response.statusCode} ${response.request?.url}',
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
    _logRequest('POST', path);
    final response = await _client.post(
      _uri(path),
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
      _uri(path),
      headers: _publicHeaders,
      body: _encode(body),
    );
    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> obtainToken(Map<String, dynamic> body) async {
    const path = '/token';
    _logRequest('POST', path);
    final response = await _client.post(
      _uri(path),
      headers: _publicHeaders,
      body: _encode(body),
    );
    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> refreshToken(Map<String, dynamic> body) async {
    const path = '/refresh';
    _logRequest('POST', path);
    final response = await _client.post(
      _uri(path),
      headers: _publicHeaders,
      body: _encode(body),
    );
    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> getMe() async {
    const path = '/me';
    _logRequest('GET', path);
    // ИСПРАВЛЕНО: используем _authHeaders, а не _publicHeaders
    final response = await _client.get(
      _uri(path),
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