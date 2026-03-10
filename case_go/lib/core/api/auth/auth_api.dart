import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

import 'auth.dart';

/// Базовая реализация [AuthApi].
///
/// Содержит URL-префикс, вспомогательные методы для HTTP-запросов
/// и логирование. Бизнес-логика делегируется в конкретные реализации
/// или дополняется здесь при необходимости.
class AuthApiImpl implements AuthApi {
  // ──────────────────────────────────────────
  // Конфигурация
  // ──────────────────────────────────────────

  final String baseUrl;
  final http.Client _client;

  /// Заголовки, не требующие авторизации.
  static const Map<String, String> _publicHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  AuthApiImpl({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  // ──────────────────────────────────────────
  // Вспомогательные методы
  // ──────────────────────────────────────────

  /// Формирует полный URI эндпоинта.
  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Сериализует тело запроса в JSON.
  String _encode(Map<String, dynamic> body) => jsonEncode(body);

  /// Десериализует JSON-ответ.
  Map<String, dynamic> _decode(http.Response response) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Логирует исходящий запрос.
  void _logRequest(String method, String path, [Object? body]) {
    dev.log(
      '→ $method $path${body != null ? ' body=$body' : ''}',
      name: 'AuthApi',
    );
  }

  /// Логирует входящий ответ.
  void _logResponse(http.Response response) {
    dev.log(
      '← ${response.statusCode} ${response.request?.url}',
      name: 'AuthApi',
    );
  }

  /// Обрабатывает ответ сервера: бросает исключение при ошибках 4xx / 5xx.
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

  // ──────────────────────────────────────────
  // Реализация интерфейса
  // ──────────────────────────────────────────
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
    final response = await _client.get(
      _uri(path),
      headers: _publicHeaders,
    );
    return _handleResponse(response);
  }
}

// ──────────────────────────────────────────
// Вспомогательные типы
// ──────────────────────────────────────────

/// Исключение, выбрасываемое при HTTP-ошибках.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}