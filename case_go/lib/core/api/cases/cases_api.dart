import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:case_go/core/api/cases/cases.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_api.dart' show ApiException;

/// Базовая реализация [TrainerApi].
///
/// Все методы требуют авторизации. Ролевые ограничения (creator / admin)
/// обеспечиваются на стороне бэкенда; клиент передаёт только токен.
class TrainerApiImpl implements TrainerApi {
  // ──────────────────────────────────────────
  // Конфигурация
  // ──────────────────────────────────────────

  final String baseUrl;
  final http.Client _client;

  /// Callback, возвращающий актуальный access-токен.
  final String Function() accessTokenProvider;

  TrainerApiImpl({
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
      (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();

  void _logRequest(String method, String path, [Object? body]) {
    dev.log(
      '→ $method $path${body != null ? ' body=$body' : ''}',
      name: 'TrainerApi',
    );
  }

  void _logResponse(http.Response response) {
    dev.log(
      '← ${response.statusCode} ${response.request?.url}',
      name: 'TrainerApi',
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

  Future<http.Response> _patch(Uri uri, Map<String, dynamic> body) async {
    final request = http.Request('PATCH', uri)
      ..headers.addAll(_authHeaders)
      ..body = _encode(body);
    return http.Response.fromStream(await _client.send(request));
  }

  // ──────────────────────────────────────────
  // Кейсы — коллекция
  // ──────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> createCase(Map<String, dynamic> body) async {
    _logRequest('POST', '/cases', body);
    final response = await _client.post(
      _uri('/cases'),
      headers: _authHeaders,
      body: _encode(body),
    );
    return _handleObject(response);
  }

  @override
  Future<Map<String, dynamic>> getCases({
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = {'page': '$page', 'page_size': '$pageSize'};
    _logRequest('GET', '/cases', query);
    final response = await _client.get(
      _uri('/cases', query),
      headers: _authHeaders,
    );
    return _handleObject(response);
  }

  @override
  Future<Map<String, dynamic>> patchCase(
    int id,
    Map<String, dynamic> body,
  ) async {
    _logRequest('PATCH', '/cases/$id', body);
    final response = await _patch(_uri('/cases/$id'), body);
    return _handleObject(response);
  }

  @override
  Future<void> deleteCase(int id) async {
    _logRequest('DELETE', '/cases/$id');
    final response = await _client.delete(
      _uri('/cases/$id'),
      headers: _authHeaders,
    );
    _handleEmpty(response);
  }

  // ──────────────────────────────────────────
  // Кейс — отдельный ресурс
  // ──────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getCase(int id) async {
    _logRequest('GET', '/cases/$id');
    final response = await _client.get(
      _uri('/cases/$id'),
      headers: _authHeaders,
    );
    return _handleObject(response);
  }

  @override
  Future<Map<String, dynamic>> submitCaseResult(
    int id,
    Map<String, dynamic> body,
  ) async {
    _logRequest('POST', '/cases/$id', body);
    final response = await _client.post(
      _uri('/cases/$id'),
      headers: _authHeaders,
      body: _encode(body),
    );
    return _handleObject(response);
  }

  // ──────────────────────────────────────────
  // История ответов
  // ──────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getHistory({int? caseId}) async {
    final query = caseId != null ? {'case_id': '$caseId'} : null;
    _logRequest('GET', '/history', query);
    final response = await _client.get(
      _uri('/history', query),
      headers: _authHeaders,
    );
    return _handleList(response);
  }

  // ──────────────────────────────────────────
  // Аналитика
  // ──────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getAnalytics([
    Map<String, String>? queryParams,
  ]) async {
    _logRequest('GET', '/analytics', queryParams);
    final response = await _client.get(
      _uri('/analytics', queryParams),
      headers: _authHeaders,
    );
    return _handleObject(response);
  }
}