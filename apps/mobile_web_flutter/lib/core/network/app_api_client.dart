import 'dart:convert';

import 'package:http/http.dart' as http;

const _apiBaseUrlHelp =
    'Make sure the backend is running and API_BASE_URL points to the backend host, like http://localhost:8000, or to the full /api/v1 prefix.';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AppApiClient {
  const AppApiClient({
    required this.baseUrl,
    this.accessToken,
  });

  final String baseUrl;
  final String? accessToken;

  String _normalizedBasePath(Uri baseUri) {
    final segments = baseUri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: true);

    if (segments.length >= 2 &&
        segments[segments.length - 2] == 'api' &&
        segments.last == 'v1') {
      segments.removeLast();
      segments.removeLast();
    } else if (segments.isNotEmpty && segments.last == 'api') {
      segments.removeLast();
    }

    return segments.isEmpty ? '' : '/${segments.join('/')}';
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final baseUri = Uri.parse(baseUrl);
    final basePath = _normalizedBasePath(baseUri);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final apiPath = '${basePath.isEmpty ? '' : basePath}/api/v1$normalizedPath';
    return baseUri.replace(
      path: apiPath,
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
  }

  Map<String, String> _headers({bool hasJsonBody = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (hasJsonBody) {
      headers['Content-Type'] = 'application/json';
    }
    if (accessToken != null && accessToken!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${accessToken!.trim()}';
    }
    return headers;
  }

  Future<http.Response> _execute(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on http.ClientException catch (error) {
      throw ApiException(
        message: 'Could not reach the backend. $_apiBaseUrlHelp ${error.message}',
      );
    } catch (_) {
      throw const ApiException(
        message: 'Network request failed. $_apiBaseUrlHelp',
      );
    }
  }

  dynamic _decodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    final body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } on FormatException {
      throw const ApiException(
        message: 'Received an invalid JSON response from the backend.',
      );
    }
  }

  Map<String, dynamic> _requireMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw const ApiException(message: 'Expected a JSON object response.');
  }

  Never _throwRequestError(http.Response response, dynamic payload) {
    final message = payload is Map<String, dynamic> && payload['detail'] is String
        ? payload['detail'] as String
        : 'Request failed with status ${response.statusCode}.';
    throw ApiException(message: message, statusCode: response.statusCode);
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _execute(
      () => http.get(
        _buildUri(path, queryParameters),
        headers: _headers(),
      ),
    );
    final payload = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }
    _throwRequestError(response, payload);
  }

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    return _requireMap(await get(path, queryParameters: queryParameters));
  }

  Future<dynamic> postJson(String path, {Object? body}) async {
    final response = await _execute(
      () => http.post(
        _buildUri(path),
        headers: _headers(hasJsonBody: true),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
    final payload = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }
    _throwRequestError(response, payload);
  }

  Future<Map<String, dynamic>> postJsonMap(String path, {Object? body}) async {
    return _requireMap(await postJson(path, body: body));
  }

  Future<dynamic> putJson(String path, {Object? body}) async {
    final response = await _execute(
      () => http.put(
        _buildUri(path),
        headers: _headers(hasJsonBody: true),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
    final payload = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }
    _throwRequestError(response, payload);
  }

  Future<Map<String, dynamic>> putJsonMap(String path, {Object? body}) async {
    return _requireMap(await putJson(path, body: body));
  }

  Future<dynamic> patchJson(String path, {Object? body}) async {
    final response = await _execute(
      () => http.patch(
        _buildUri(path),
        headers: _headers(hasJsonBody: true),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
    final payload = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }
    _throwRequestError(response, payload);
  }

  Future<Map<String, dynamic>> patchJsonMap(String path, {Object? body}) async {
    return _requireMap(await patchJson(path, body: body));
  }

  Future<dynamic> delete(String path) async {
    final response = await _execute(
      () => http.delete(
        _buildUri(path),
        headers: _headers(),
      ),
    );
    final payload = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }
    _throwRequestError(response, payload);
  }
}
