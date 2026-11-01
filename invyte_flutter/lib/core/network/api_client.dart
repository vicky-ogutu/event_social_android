import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';
import '../error/failure.dart';
import '../storage/token_store.dart';

typedef _RequestBuilder = Future<http.BaseRequest> Function();

enum _RefreshResult { refreshed, rejected }

/// Thin wrapper over `package:http` that:
/// * attaches the bearer access token,
/// * transparently renews it with the refresh token on a 401 and retries,
/// * encodes/decodes JSON and unwraps the `{ success, message, data }` envelope,
/// * converts every error into a [Failure].
class ApiClient {
  ApiClient({
    required http.Client client,
    required String baseUrl,
    required TokenStore tokens,
    void Function()? onSessionExpired,
    Duration timeout = AppConfig.requestTimeout,
  })  : _client = client,
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _tokens = tokens,
        _onSessionExpired = onSessionExpired,
        _timeout = timeout;

  final http.Client _client;
  final String _baseUrl;
  final TokenStore _tokens;
  final void Function()? _onSessionExpired;
  final Duration _timeout;

  /// In-flight refresh shared by every request that hit a 401 at once, so the
  /// single-use refresh token is only spent once.
  Future<_RefreshResult>? _refreshing;

  Future<dynamic> get(String path, {Map<String, Object?>? query}) => _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) => _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Multipart upload of a single file plus optional text [fields].
  Future<dynamic> upload(
    String path, {
    required String fileField,
    required String filePath,
    Map<String, String> fields = const {},
  }) {
    return _execute(path, () async {
      return http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers(json: false))
        ..fields.addAll(fields)
        ..files.add(await http.MultipartFile.fromPath(
          fileField,
          filePath,
          contentType: _mediaTypeFor(filePath),
        ));
    });
  }

  Future<dynamic> _send(String method, String path, {Map<String, Object?>? query, Object? body}) {
    return _execute(path, () async {
      final request = http.Request(method, _uri(path, query))..headers.addAll(_headers(json: body != null));
      if (body != null) request.body = jsonEncode(body);
      return request;
    });
  }

  Future<dynamic> _execute(String path, _RequestBuilder build) async {
    final sentToken = _tokens.accessToken;
    var response = await _transport(await build());

    if (response.statusCode == 401 && sentToken != null && _isRefreshable(path)) {
      if (await _refresh(sentToken) == _RefreshResult.refreshed) {
        // Rebuild so the retry carries the new access token.
        response = await _transport(await build());
      } else {
        _onSessionExpired?.call();
      }
    }
    return _handle(response);
  }

  /// Sign-in endpoints answer 401 for bad credentials, not expired sessions.
  static bool _isRefreshable(String path) {
    final p = path.startsWith('/') ? path.substring(1) : path;
    return !p.startsWith('api/auth/') || p == 'api/auth/me' || p == 'api/auth/logout-all';
  }

  Future<_RefreshResult> _refresh(String failedToken) {
    final current = _tokens.accessToken;
    // Another request already renewed the token after this one was sent.
    if (current != null && current != failedToken) return Future.value(_RefreshResult.refreshed);
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<_RefreshResult> _doRefresh() async {
    final refreshToken = _tokens.refreshToken;
    if (refreshToken == null) return _RefreshResult.rejected;

    final request = http.Request('POST', _uri('api/auth/refresh'))
      ..headers.addAll({'Accept': 'application/json', 'Content-Type': 'application/json; charset=utf-8'})
      ..body = jsonEncode({'refresh_token': refreshToken});
    // Network errors propagate as NetworkFailure: being offline must not sign
    // the user out.
    final response = await _transport(request);
    if (response.statusCode != 200) return _RefreshResult.rejected;

    final data = _decode(response.body);
    final payload = data is Map ? data['data'] : null;
    final access = payload is Map ? (payload['access_token'] ?? payload['token']) : null;
    if (access is! String) return _RefreshResult.rejected;
    final rotated = payload['refresh_token'];
    await _tokens.save(accessToken: access, refreshToken: rotated is String ? rotated : null);
    return _RefreshResult.refreshed;
  }

  Future<http.Response> _transport(http.BaseRequest request) async {
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      return await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw const NetworkFailure('The server took too long to respond. Please try again.');
    } on http.ClientException {
      throw const NetworkFailure();
    }
  }

  dynamic _handle(http.Response response) {
    final decoded = _decode(response.body);
    final status = response.statusCode;

    if (status >= 200 && status < 300) {
      if (decoded is Map && decoded['success'] == false) {
        throw Failure(_messageFrom(decoded) ?? 'Request failed', statusCode: status, code: _codeFrom(decoded));
      }
      return decoded is Map && decoded.containsKey('success') ? decoded['data'] : decoded;
    }

    throw Failure(
      _messageFrom(decoded) ?? _defaultMessageFor(status),
      statusCode: status,
      code: _codeFrom(decoded),
    );
  }

  Uri _uri(String path, [Map<String, Object?>? query]) {
    final params = <String, String>{
      for (final entry in (query ?? const <String, Object?>{}).entries)
        if (entry.value != null && entry.value.toString().isNotEmpty) entry.key: entry.value.toString(),
    };
    final uri = Uri.parse('$_baseUrl/${path.startsWith('/') ? path.substring(1) : path}');
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  Map<String, String> _headers({required bool json}) {
    final token = _tokens.accessToken;
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json; charset=utf-8',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static String? _codeFrom(Object? decoded) =>
      decoded is Map && decoded['code'] is String ? decoded['code'] as String : null;

  static String? _messageFrom(Object? decoded) {
    if (decoded is! Map) return null;
    final message = decoded['message'] ?? decoded['error'];
    if (message is String && message.isNotEmpty) return message;
    final errors = decoded['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map && first['msg'] is String) return first['msg'] as String;
      return first.toString();
    }
    return null;
  }

  static String _defaultMessageFor(int status) => switch (status) {
        400 => 'Please check the details and try again.',
        401 => 'Your session has expired. Please sign in again.',
        403 => 'You don\'t have permission to do that.',
        404 => 'We couldn\'t find what you were looking for.',
        429 => 'Too many attempts. Please wait a few minutes and try again.',
        >= 500 => 'Invyte is having trouble right now. Please try again shortly.',
        _ => 'Request failed ($status).',
      };

  static MediaType _mediaTypeFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => MediaType('image', 'png'),
      'gif' => MediaType('image', 'gif'),
      'webp' => MediaType('image', 'webp'),
      'heic' => MediaType('image', 'heic'),
      'mp4' => MediaType('video', 'mp4'),
      'mov' => MediaType('video', 'quicktime'),
      _ => MediaType('image', 'jpeg'),
    };
  }
}
