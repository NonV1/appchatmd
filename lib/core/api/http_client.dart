// lib/core/api/http_client.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// ------------------------------
/// Config & Contracts
/// ------------------------------
class ApiConfig {
  ApiConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
    this.healthPath = '/health',
    this.defaultHeaders = const {'content-type': 'application/json'},
  });

  /// เช่น https://api.chatdm.org
  final String baseUrl;

  /// timeout รวม (connect+read)
  final Duration timeout;

  /// ใช้ ping ตรวจเซิร์ฟเวอร์
  final String healthPath;

  /// เฮดเดอร์พื้นฐาน
  final Map<String, String> defaultHeaders;
}

/// ตัวดึง token ปัจจุบัน (อ่านจาก Session/Storage)
typedef TokenProvider = Future<String?> Function();

/// callback เมื่อโดน 401 ให้ UI logout หรือวิ่ง refresh ตามที่กำหนด
typedef UnauthorizedHandler = Future<void> Function();

/// optional: refresh token (ถ้าอยากทำ auto-refresh ภายหลัง)
typedef TokenRefresher = Future<bool> Function();

/// ------------------------------
/// Errors (จับง่ายใน UI/Service)
/// ------------------------------
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => '$runtimeType($statusCode): $message';
}

class NetworkException extends ApiException {
  const NetworkException(super.message);
}

class TimeoutExceptionApi extends ApiException {
  const TimeoutExceptionApi(super.message);
}

class BadRequestException extends ApiException {
  const BadRequestException(super.message, {int? status})
      : super(statusCode: status);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message, {int? status})
      : super(statusCode: status);
}

class ServerException extends ApiException {
  const ServerException(super.message, {int? status})
      : super(statusCode: status);
}

class ParseException extends ApiException {
  const ParseException(super.message);
}

/// ------------------------------
/// ApiClient (ตัวเดียวจบ)
/// ------------------------------
class ApiClient {
  ApiClient(
    this._config, {
    required this.tokenProvider,
    this.onUnauthorized,
    this.refreshToken, // ยังไม่ใช้โดยอัตโนมัติในเวอร์ชันแรก
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final ApiConfig _config;
  final http.Client _http;
  final TokenProvider tokenProvider;
  final UnauthorizedHandler? onUnauthorized;
  final TokenRefresher? refreshToken;

  /// ปิด client ตอนเลิกใช้ (เช่นใน dispose ของ service)
  void close() => _http.close();

  /// ping เซิร์ฟเวอร์ -> true/false
  Future<bool> isServerReachable() async {
    try {
      final uri = _buildUri(_config.healthPath);
      final res = await _http
          .get(uri)
          .timeout(_config.timeout);
      return res.statusCode >= 200 && res.statusCode < 500;
    } on Exception {
      return false;
    }
  }

  /// --------------------------
  /// Public HTTP methods
  /// --------------------------
  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    return _send('GET', path, headers: headers, query: query);
  }

  Future<dynamic> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    return _send('POST', path, headers: headers, body: body, query: query);
  }

  Future<dynamic> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    return _send('PUT', path, headers: headers, body: body, query: query);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    return _send('DELETE', path, headers: headers, body: body, query: query);
  }

  /// --------------------------
  /// Core request flow
  /// --------------------------
  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final uri = _buildUri(path, query: query);
    final h = await _buildHeaders(headers);

    http.Response res;
    try {
      switch (method) {
        case 'GET':
          res = await _http.get(uri, headers: h).timeout(_config.timeout);
          break;
        case 'POST':
          res = await _http
              .post(uri, headers: h, body: _encodeIfJson(h, body))
              .timeout(_config.timeout);
          break;
        case 'PUT':
          res = await _http
              .put(uri, headers: h, body: _encodeIfJson(h, body))
              .timeout(_config.timeout);
          break;
        case 'DELETE':
          res = await _http
              .delete(uri, headers: h, body: _encodeIfJson(h, body))
              .timeout(_config.timeout);
          break;
        default:
          throw ArgumentError('Unsupported method: $method');
      }
    } on http.ClientException catch (e) {
      throw NetworkException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้: ${e.message}');
    } on TimeoutException {
      throw TimeoutExceptionApi('เครือข่ายช้า หรือเซิร์ฟเวอร์ตอบสนองช้า');
    } catch (e) {
      throw NetworkException('ข้อผิดพลาดเครือข่าย: $e');
    }

    // แปลง/โยน error ตามสถานะ
    return _handleResponse(res);
  }

  /// รวม baseUrl + path + query
  Uri _buildUri(String path, {Map<String, dynamic>? query}) {
    final normBase = _config.baseUrl.endsWith('/')
        ? _config.baseUrl.substring(0, _config.baseUrl.length - 1)
        : _config.baseUrl;
    final normPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normBase$normPath');

    if (query == null || query.isEmpty) return uri;

    // แปลงเป็น queryParameters แบบ String
    final qp = <String, String>{};
    query.forEach((k, v) {
      if (v == null) return;
      if (v is Iterable) {
        // เก็บค่าแรก (หรือจะเปลี่ยนเป็น k[]=a&k[]=b ก็ได้ในอนาคต)
        final first = v.isEmpty ? null : v.first;
        if (first != null) qp[k] = first.toString();
      } else {
        qp[k] = v.toString();
      }
    });
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...qp,
    });
  }

  /// เตรียม headers + ใส่ Authorization (ถ้ามี)
  Future<Map<String, String>> _buildHeaders(Map<String, String>? headers) async {
    final merged = <String, String>{..._config.defaultHeaders, ...?headers};

    // ใส่ bearer ถ้ามี token
    final token = await tokenProvider();
    if (token != null && token.isNotEmpty) {
      merged['authorization'] = 'Bearer $token';
    }

    return merged;
  }

  /// ถ้าเป็น JSON header ให้แปลง body เป็น json
  Object? _encodeIfJson(Map<String, String> headers, Object? body) {
    if (body == null) return null;
    final ct = headers['content-type']?.toLowerCase() ?? '';
    if (ct.contains('application/json')) {
      if (body is String) return body; // assume already json encoded
      return jsonEncode(body);
    }
    return body;
  }

  dynamic _handleResponse(http.Response res) {
    final code = res.statusCode;
    final bodyStr = res.body;

    dynamic data;
    if (bodyStr.isNotEmpty) {
      try {
        data = jsonDecode(bodyStr);
      } catch (_) {
        // ไม่ใช่ JSON ก็คืนเป็น string ไป
        data = bodyStr;
      }
    }

    if (code >= 200 && code < 300) {
      return data;
    }

    // Map error โดยดูโครง FastAPI ที่เราใช้ (detail)
    String message = 'HTTP $code';
    if (data is Map && data['detail'] != null) {
      message = data['detail'].toString();
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    switch (code) {
      case 400:
        throw BadRequestException(message, status: code);
      case 401:
        // แจ้ง handler ให้เคลียร์ session / พาไป login
        if (onUnauthorized != null) {
          // fire-and-forget ก็ได้ แต่เรารอให้จบก่อน
          return onUnauthorized!().then((_) {
            throw UnauthorizedException(message, status: code);
          });
        }
        throw UnauthorizedException(message, status: code);
      case 403:
        throw UnauthorizedException('Forbidden: $message', status: code);
      case 404:
        throw BadRequestException('Not Found: $message', status: code);
      default:
        throw ServerException(message, status: code);
    }
  }
}

/// ------------------------------
/// Lightweight response wrapper
/// ------------------------------
class HttpResponse<T> {
  const HttpResponse({required this.data, this.statusCode});
  final T data;
  final int? statusCode;
}

/// ------------------------------
/// Global HttpClient singleton
/// ------------------------------
class HttpClient {
  HttpClient._();

  static final HttpClient I = HttpClient._();

  ApiClient? _client;

  bool get isReady => _client != null;

  ApiClient get rawClient {
    final client = _client;
    if (client == null) {
      throw StateError(
        'HttpClient not initialized. Call HttpClient.I.init(...) first.',
      );
    }
    return client;
  }

  void init({
    required String baseUrl,
    Duration timeout = const Duration(seconds: 15),
    String healthPath = '/health',
    Map<String, String> defaultHeaders = const {
      'content-type': 'application/json',
    },
    TokenProvider? getToken,
    UnauthorizedHandler? onUnauthorized,
    TokenRefresher? refreshToken,
    http.Client? httpClient,
  }) {
    _client = ApiClient(
      ApiConfig(
        baseUrl: baseUrl,
        timeout: timeout,
        healthPath: healthPath,
        defaultHeaders: defaultHeaders,
      ),
      tokenProvider: getToken ?? () async => null,
      onUnauthorized: onUnauthorized,
      refreshToken: refreshToken,
      httpClient: httpClient,
    );
  }

  /// ใช้คู่กับ unit test/DI
  void configure(ApiClient client) {
    _client = client;
  }

  Future<HttpResponse<dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final data = await rawClient.get(path, headers: headers, query: query);
    return HttpResponse<dynamic>(data: data);
  }

  Future<HttpResponse<dynamic>> postJson(
    String path,
    Object? body, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final mergedHeaders = {
      'content-type': 'application/json',
      ...?headers,
    };
    final data = await rawClient.post(
      path,
      headers: mergedHeaders,
      body: body,
      query: query,
    );
    return HttpResponse<dynamic>(data: data);
  }

  Future<HttpResponse<dynamic>> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final data = await rawClient.put(
      path,
      headers: headers,
      body: body,
      query: query,
    );
    return HttpResponse<dynamic>(data: data);
  }

  Future<HttpResponse<dynamic>> delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final data = await rawClient.delete(
      path,
      headers: headers,
      body: body,
      query: query,
    );
    return HttpResponse<dynamic>(data: data);
  }

  Future<bool> pingHealth() async => rawClient.isServerReachable();
}
