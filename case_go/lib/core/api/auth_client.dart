import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:case_go/core/storage/storage.dart';

/// HTTP-клиент с автоматическим обновлением JWT-токена.
///
/// При получении 401 от любого защищённого эндпоинта:
///  1. Отправляет запрос на обновление токена (POST [_refreshUri]).
///  2. Сохраняет новый access-token в [StorageService].
///  3. Повторяет оригинальный запрос с новым токеном.
///
/// Если refresh-токен недействителен или отсутствует — очищает все токены
/// (после чего HomeBloc при следующем запросе разлогинит пользователя).
///
/// Одновременные 401 дедуплицируются: только один refresh-запрос будет
/// отправлен, а все ожидающие запросы подождут его результата.
class AuthHttpClient extends http.BaseClient {
  final StorageService _storage;
  final Uri _refreshUri;
  final http.Client _inner;

  /// Guard против одновременных refresh-запросов.
  Future<bool>? _refreshFuture;

  AuthHttpClient({
    required StorageService storage,
    required String refreshUrl,
    http.Client? inner,
  })  : _storage = storage,
        _refreshUri = Uri.parse(refreshUrl),
        _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Attach current access-token to every outgoing request
    _attachToken(request);

    final response = await _inner.send(request);

    // Only intercept 401 on non-refresh endpoints to avoid infinite loop
    if (response.statusCode != 401 ||
        request.url.path == _refreshUri.path) {
      return response;
    }

    dev.log(
      '← 401 on ${request.url.path} — attempting token refresh',
      name: 'AuthHttpClient',
    );

    // Dedup: if another request is already refreshing, await the same future
    final refreshed = await (_refreshFuture ??=
        _doRefresh().whenComplete(() => _refreshFuture = null));

    if (!refreshed) {
      dev.log('← refresh failed, propagating 401', name: 'AuthHttpClient');
      return response;
    }

    // Retry original request with the new token
    final retryReq = _cloneRequest(request);
    _attachToken(retryReq);
    dev.log('→ retrying ${request.method} ${request.url.path}',
        name: 'AuthHttpClient');
    return _inner.send(retryReq);
  }

  void _attachToken(http.BaseRequest request) {
    final token = _storage.accessTokenSync;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<bool> _doRefresh() async {
    final refreshToken = _storage.refreshTokenSync;
    if (refreshToken == null || refreshToken.isEmpty) {
      dev.log('← no refresh token available — clearing session',
          name: 'AuthHttpClient');
      await _storage.clearAll();
      return false;
    }

    try {
      final resp = await _inner.post(
        _refreshUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refreshToken}),
      );

      dev.log('← refresh response: ${resp.statusCode} ${resp.body}',
          name: 'AuthHttpClient');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        // Сервер может вернуть "access" или "access_token"
        final newAccess =
            (data['access'] ?? data['access_token']) as String?;
        if (newAccess != null && newAccess.isNotEmpty) {
          await _storage.setAccessToken(newAccess);
          dev.log('← access token refreshed successfully',
              name: 'AuthHttpClient');
          return true;
        }
      }

      dev.log(
          '← refresh failed (${resp.statusCode}) — clearing session',
          name: 'AuthHttpClient');
      await _storage.clearAll();
      return false;
    } catch (e) {
      dev.log('← refresh exception: $e — clearing session',
          name: 'AuthHttpClient');
      await _storage.clearAll();
      return false;
    }
  }

  /// Создаёт клон оригинального запроса с теми же параметрами.
  /// Тело безопасно копировать — [http.Request] хранит его как байты.
  http.BaseRequest _cloneRequest(http.BaseRequest original) {
    if (original is http.Request) {
      return http.Request(original.method, original.url)
        ..headers.addAll(original.headers)
        ..bodyBytes = original.bodyBytes
        ..encoding = original.encoding
        ..followRedirects = original.followRedirects
        ..maxRedirects = original.maxRedirects;
    }
    // Для нестандартных типов запросов (multipart и т.п.) просто возвращаем
    // оригинал — повтор невозможен, но это редкий случай для наших API.
    dev.log(
      '⚠️ Cannot clone ${original.runtimeType}, skip retry',
      name: 'AuthHttpClient',
    );
    return original;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
