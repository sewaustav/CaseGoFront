import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

import '../auth/auth_api.dart' show ApiException;
import 'profile.dart';

class ProfileApiImpl implements ProfileApi {
  final String baseUrl;
  final String Function() accessTokenProvider;
  final http.Client _client;

  ProfileApiImpl({
    required this.baseUrl,
    required this.accessTokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${accessTokenProvider()}',
      };

  String _encode(Map<String, dynamic> body) => jsonEncode(body);

  Map<String, dynamic> _decodeObject(http.Response r) =>
      jsonDecode(r.body) as Map<String, dynamic>;

  List<Map<String, dynamic>> _decodeList(http.Response r) =>
      (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();

  void _log(String method, String path, [Object? body]) =>
      dev.log('→ $method $path${body != null ? ' body=$body' : ''}',
          name: 'ProfileApi');

  void _logResp(http.Response r) =>
      dev.log('← ${r.statusCode} ${r.request?.url}', name: 'ProfileApi');

  Map<String, dynamic> _handleObject(http.Response r) {
    _logResp(r);
    if (r.statusCode >= 200 && r.statusCode < 300) return _decodeObject(r);
    throw ApiException(statusCode: r.statusCode, message: r.body);
  }

  List<Map<String, dynamic>> _handleList(http.Response r) {
    _logResp(r);
    if (r.statusCode >= 200 && r.statusCode < 300) return _decodeList(r);
    throw ApiException(statusCode: r.statusCode, message: r.body);
  }

  void _handleEmpty(http.Response r) {
    _logResp(r);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ApiException(statusCode: r.statusCode, message: r.body);
    }
  }

  Future<http.Response> _patch(String path, Map<String, dynamic> body) async {
    final req = http.Request('PATCH', _uri(path))
      ..headers.addAll(_authHeaders)
      ..body = _encode(body);
    return http.Response.fromStream(await _client.send(req));
  }

  // ── Profile ───────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> createProfile(Map<String, dynamic> body) async {
    _log('POST', '/profile', body);
    final r = await _client.post(_uri('/profile'),
        headers: _authHeaders, body: _encode(body));
    return _handleObject(r);
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    _log('GET', '/profile');
    final r = await _client.get(_uri('/profile'), headers: _authHeaders);
    return _handleObject(r);
  }

  @override
  Future<Map<String, dynamic>> replaceProfile(Map<String, dynamic> body) async {
    _log('PUT', '/profile', body);
    final r = await _client.put(_uri('/profile'),
        headers: _authHeaders, body: _encode(body));
    return _handleObject(r);
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    _log('PATCH', '/profile', body);
    final r = await _patch('/profile', body);
    return _handleObject(r);
  }

  @override
  Future<void> deleteProfile() async {
    _log('DELETE', '/profile');
    final r = await _client.delete(_uri('/profile'), headers: _authHeaders);
    _handleEmpty(r);
  }

  // ── Social ────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> createSocialLink(
      Map<String, dynamic> body) async {
    _log('POST', '/profile/social', body);
    final r = await _client.post(_uri('/profile/social'),
        headers: _authHeaders, body: _encode(body));
    return _handleObject(r);
  }

  @override
  Future<Map<String, dynamic>> replaceSocialLink(
      int id, Map<String, dynamic> body) async {
    _log('PUT', '/profile/social/$id', body);
    final r = await _client.put(_uri('/profile/social/$id'),
        headers: _authHeaders, body: _encode(body));
    return _handleObject(r);
  }

  @override
  Future<void> deleteSocialLink(int id) async {
    _log('DELETE', '/profile/social/$id');
    final r = await _client.delete(_uri('/profile/social/$id'),
        headers: _authHeaders);
    _handleEmpty(r);
  }

  // ── Purpose ───────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> createPurpose(
      Map<String, dynamic> body) async {
    _log('POST', '/profile/purpose', body);
    final r = await _client.post(_uri('/profile/purpose'),
        headers: _authHeaders, body: _encode(body));
    return _handleObject(r);
  }

  @override
  Future<Map<String, dynamic>> replacePurpose(
      int id, Map<String, dynamic> body) async {
    _log('PUT', '/profile/purpose/$id', body);
    final r = await _client.put(_uri('/profile/purpose/$id'),
        headers: _authHeaders, body: _encode(body));
    return _handleObject(r);
  }

  @override
  Future<void> deletePurpose(int id) async {
    _log('DELETE', '/profile/purpose/$id');
    final r = await _client.delete(_uri('/profile/purpose/$id'),
        headers: _authHeaders);
    _handleEmpty(r);
  }

  // ── Profession ────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> createProfession(
      Map<String, dynamic> body) async {
    _log('POST', '/profession', body);
    final r = await _client.post(_uri('/profession'),
        headers: _authHeaders, body: _encode(body));
    return _handleObject(r);
  }

  @override
  Future<List<Map<String, dynamic>>> getProfessions() async {
    _log('GET', '/profession');
    final r = await _client.get(_uri('/profession'), headers: _authHeaders);
    return _handleList(r);
  }

  @override
  Future<Map<String, dynamic>> replaceProfession(
      int id, Map<String, dynamic> body) async {
    _log('PUT', '/profession/$id', body);
    final r = await _client.put(_uri('/profession/$id'),
        headers: _authHeaders, body: _encode(body));
    return _handleObject(r);
  }

  @override
  Future<void> deleteProfession(int id) async {
    _log('DELETE', '/profession/$id');
    final r = await _client.delete(_uri('/profession/$id'),
        headers: _authHeaders);
    _handleEmpty(r);
  }
}