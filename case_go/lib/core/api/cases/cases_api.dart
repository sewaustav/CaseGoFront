import 'dart:convert';
import 'dart:developer' as dev;
import 'package:case_go/core/api/auth/auth_api.dart' show ApiException;
import 'package:case_go/core/api/cases/cases.dart';
import 'package:http/http.dart' as http;

class CaseGoApiImpl implements CaseGoApi {
  final String baseUrl;
  final String Function() accessTokenProvider;
  final http.Client _client;

  CaseGoApiImpl({
    required this.baseUrl,
    required this.accessTokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, String>? q]) {
    final uri = Uri.parse('$baseUrl$path');
    return q != null ? uri.replace(queryParameters: q) : uri;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${accessTokenProvider()}',
      };

  void _log(String method, String path, [Object? body]) =>
      dev.log('→ $method $path${body != null ? ' $body' : ''}',
          name: 'CaseGoApi');

  void _logResp(http.Response r) =>
      dev.log('← ${r.statusCode} ${r.request?.url}', name: 'CaseGoApi');

  Map<String, dynamic> _handleObject(http.Response r) {
    _logResp(r);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw ApiException(statusCode: r.statusCode, message: r.body);
  }

  List<Map<String, dynamic>> _handleList(http.Response r) {
    _logResp(r);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final body = jsonDecode(r.body);
      if (body is List) return body.cast<Map<String, dynamic>>();
      // Backend may wrap in object
      if (body is Map && body.containsKey('cases')) {
        return (body['cases'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    }
    throw ApiException(statusCode: r.statusCode, message: r.body);
  }

  @override
  Future<List<Map<String, dynamic>>> getCases({
    int limit = 20,
    int page = 1,
    String? topic,
    int? category,
  }) async {
    _log('GET', '/cases', {'limit': limit, 'page': page});
    final q = <String, String>{'limit': '$limit', 'page': '$page'};
    if (topic != null && topic.isNotEmpty) q['topic'] = topic;
    if (category != null) q['category'] = '$category';
    final r = await _client.get(_uri('/cases', q), headers: _headers);
    return _handleList(r);
  }

  @override
  Future<Map<String, dynamic>> getCaseById(int caseId) async {
    _log('GET', '/cases/$caseId');
    final r = await _client.get(_uri('/cases/$caseId'), headers: _headers);
    return _handleObject(r);
  }

  @override
  Future<Map<String, dynamic>> startCase(int caseId) async {
    _log('POST', '/cases/$caseId');
    final r = await _client.post(
      _uri('/cases/$caseId'),
      headers: _headers,
      body: jsonEncode({'case_id': caseId}),
    );
    return _handleObject(r);
  }

  @override
  Future<Map<String, dynamic>> sendInteraction(
    int dialogId,
    Map<String, dynamic> body,
  ) async {
    _log('POST', '/dialog', body);
    final r = await _client.post(
      _uri('/dialog'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleObject(r);
  }

  @override
  Future<Map<String, dynamic>> completeDialog(int dialogId) async {
    _log('POST', '/dialogs/$dialogId/complete');
    final r = await _client.post(
      _uri('/dialogs/$dialogId/complete'),
      headers: _headers,
      body: jsonEncode({}),
    );
    return _handleObject(r);
  }

  @override
  Future<Map<String, dynamic>> getDialogById(int dialogId) async {
    _log('GET', '/dialogs/$dialogId');
    final r =
        await _client.get(_uri('/dialogs/$dialogId'), headers: _headers);
    return _handleObject(r);
  }

  @override
  Future<List<Map<String, dynamic>>> getUserDialogs(
    int userId, {
    int limit = 20,
    int page = 1,
  }) async {
    _log('GET', '/users/$userId/dialogs');
    final q = {
      'userID': '$userId',
      'limit': '$limit',
      'page': '$page',
    };
    final r = await _client.get(_uri('/users/$userId/dialogs', q),
        headers: _headers);
    return _handleList(r);
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    _log('GET', '/admin/stats');
    final r = await _client.get(_uri('/admin/stats'), headers: _headers);
    return _handleObject(r);
  }

  @override
  Future<Map<String, dynamic>> createCase(Map<String, dynamic> body) async {
    _log('POST', '/case', body);
    final r = await _client.post(
      _uri('/case'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleObject(r);
  }

  @override
  Future<Map<String, dynamic>> updateCase(
      int caseId, Map<String, dynamic> body) async {
    _log('PUT', '/case/$caseId', body);
    final r = await _client.put(
      _uri('/case/$caseId'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleObject(r);
  }

  @override
  Future<void> deleteCase(int caseId) async {
    _log('DELETE', '/case/$caseId');
    final r = await _client.delete(_uri('/case/$caseId'), headers: _headers);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ApiException(statusCode: r.statusCode, message: r.body);
    }
  }
}
