import 'dart:convert';
import 'dart:developer' as dev;
import 'package:case_go/core/api/case_profile/case_profile.dart';
import 'package:case_go/core/api/auth/auth_api.dart' show ApiException;
import 'package:http/http.dart' as http;

class CaseProfileApiImpl implements CaseProfileApi {
  final String baseUrl;
  final String Function() accessTokenProvider;
  final http.Client _client;

  CaseProfileApiImpl({
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

  void _log(String method, String path) =>
      dev.log('→ $method $path', name: 'CaseProfileApi');

  void _logResp(http.Response r) =>
      dev.log('← ${r.statusCode} ${r.request?.url}', name: 'CaseProfileApi');

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
      return [];
    }
    throw ApiException(statusCode: r.statusCode, message: r.body);
  }

  @override
  Future<Map<String, dynamic>> getSkillsProfile() async {
    _log('GET', '/profile');
    final r = await _client.get(_uri('/profile'), headers: _headers);
    return _handleObject(r);
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory({String? from}) async {
    _log('GET', '/history');
    final q = from != null ? {'from': from} : null;
    final r = await _client.get(_uri('/history', q), headers: _headers);
    return _handleList(r);
  }
}
