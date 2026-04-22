import 'dart:convert';
import 'dart:developer' as dev;
import 'package:case_go/core/api/auth/auth_api.dart' show ApiException;
import 'package:case_go/core/api/admin/admin.dart';
import 'package:http/http.dart' as http;

class AdminApiImpl implements AdminApi {
  final String usersBaseUrl;
  final String Function() accessTokenProvider;
  final http.Client _client;

  AdminApiImpl({
    required this.usersBaseUrl,
    required this.accessTokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${accessTokenProvider()}',
      };

  void _log(String method, String path) =>
      dev.log('→ $method $path', name: 'AdminApi');

  Map<String, dynamic> _handleObject(http.Response r) {
    dev.log('← ${r.statusCode} ${r.request?.url}', name: 'AdminApi');
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw ApiException(statusCode: r.statusCode, message: r.body);
  }

  List<Map<String, dynamic>> _handleList(http.Response r) {
    dev.log('← ${r.statusCode} ${r.request?.url}', name: 'AdminApi');
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final body = jsonDecode(r.body);
      if (body is List) return body.cast<Map<String, dynamic>>();
      return [];
    }
    throw ApiException(statusCode: r.statusCode, message: r.body);
  }

  @override
  Future<List<Map<String, dynamic>>> getUsers() async {
    _log('GET', '/');
    final r = await _client.get(
      Uri.parse('$usersBaseUrl/'),
      headers: _headers,
    );
    return _handleList(r);
  }

  @override
  Future<Map<String, dynamic>> updateUserRole(int userId, int role) async {
    _log('PATCH', '/$userId/role');
    final r = await _client.patch(
      Uri.parse('$usersBaseUrl/$userId/role'),
      headers: _headers,
      body: jsonEncode({'role': role}),
    );
    return _handleObject(r);
  }
}
