// lib/core/auth/auth_service.dart
import 'dart:async';
import 'package:meta/meta.dart';

import '../api/http_client.dart';
import '../user/session.dart';
import '../models/user_profile.dart';

/// ประเภทความล้มเหลว ใช้แยกแสดงข้อความใน UI ได้ง่าย
enum AuthErrorType { network, timeout, unauthorized, badRequest, server, unknown }

@immutable
class AuthException implements Exception {
  const AuthException(this.type, this.message);
  final AuthErrorType type;
  final String message;

  @override
  String toString() => 'AuthException($type): $message';
}

/// ผลลัพธ์การล็อกอิน/สมัคร
@immutable
class AuthResult {
  const AuthResult({required this.ok, this.message});
  final bool ok;
  final String? message;
}

/// Service เดียวดูแลการล็อกอิน/สมัคร/ออกจากระบบ + ดึง profile
class AuthService {
  AuthService({
    required ApiClient api,
    required Session session,
  })  : _api = api,
        _session = session;

  AuthService._internal(this._api, this._session);

  static AuthService? _singleton;

  /// เข้าถึง singleton หลัก (เรียกได้ทันทีหลัง HttpClient.I.init())
  static AuthService get I =>
      _singleton ??= AuthService._internal(HttpClient.I.rawClient, Session.I);

  static AuthService get instance => I;

  /// ใช้ใน unit test หรือกรณีพิเศษเพื่อฉีด dependency เอง
  static void configure({
    ApiClient? api,
    Session? session,
  }) {
    _singleton = AuthService._internal(
      api ?? HttpClient.I.rawClient,
      session ?? Session.I,
    );
  }

  final ApiClient _api;
  final Session _session;

  /// สมัครสมาชิก (สมัครสำเร็จ → ล็อกอินอัตโนมัติ)
  Future<AuthResult> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      await _api.post('/auth/register', body: {
        'display_name': displayName.trim(),
        'email': email.trim(),
        'password': password,
      });

      // สมัครผ่านแล้ว ลองล็อกอินต่อเลย
      return await login(email: email, password: password);
    } on ApiException catch (e) {
      throw _mapApiException(e);
    } catch (e) {
      throw const AuthException(AuthErrorType.unknown, 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ');
    }
  }

  /// ล็อกอิน (เก็บ access_token ลง Session)
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _api.post('/auth/login', body: {
        'email': email.trim(),
        'password': password,
      });

      // รองรับทั้ง {access_token: "..."} หรือ data อื่น ๆ
      final token = (res is Map && res['access_token'] is String)
          ? (res['access_token'] as String)
          : null;

      if (token == null || token.isEmpty) {
        throw const AuthException(AuthErrorType.server, 'รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
      }

      await _session.saveAccessToken(token);
      await _session.saveEmail(email.trim());
      // display_name อาจมาทีหลังจาก /me
      return const AuthResult(ok: true);
    } on ApiException catch (e) {
      throw _mapApiException(e);
    } catch (e) {
      throw const AuthException(AuthErrorType.unknown, 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ');
    }
  }

  /// ออกจากระบบ (ล้าง token/local profile)
  Future<void> logout() async {
    await _session.clear();
  }

  /// ดึงโปรไฟล์ปัจจุบัน (ต้องมี token)
  Future<UserProfile?> me() async {
    try {
      final res = await _api.get('/me');
      if (res is Map<String, dynamic>) {
        return UserProfile.fromJson(res);
      }
      return null;
    } on ApiException catch (e) {
      // ถ้า token ใช้ไม่ได้แล้ว ให้โยน Unauthorized เพื่อให้ UI พาไป login
      final mapped = _mapApiException(e);
      if (mapped.type == AuthErrorType.unauthorized) {
        rethrow;
      }
      return null;
    }
  }

  /// เช็กว่ามี token ไหม (สำหรับตัดสินใจ initial route)
  Future<bool> isAuthenticated() async => (await _session.readAccessToken())?.isNotEmpty == true;

  /// ping เซิร์ฟเวอร์ (ใช้โชว์แบนเนอร์ “เซิร์ฟเวอร์ขัดข้อง/ไม่มีเน็ต”)
  Future<bool> isServerReachable() => _api.isServerReachable();

  /// แปลง ApiException → AuthException ที่ UI เข้าใจง่าย
  AuthException _mapApiException(ApiException e) {
    if (e is NetworkException) {
      return const AuthException(AuthErrorType.network, 'ไม่พบการเชื่อมต่ออินเทอร์เน็ต');
    }
    if (e is TimeoutExceptionApi) {
      return const AuthException(AuthErrorType.timeout, 'เครือข่ายช้าหรือเซิร์ฟเวอร์ตอบสนองช้า');
    }
    if (e is UnauthorizedException) {
      return const AuthException(AuthErrorType.unauthorized, 'อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    }
    if (e is BadRequestException) {
      // เซิร์ฟเวอร์อาจส่งข้อความเช่น "email already registered"
      return AuthException(AuthErrorType.badRequest, e.message);
    }
    if (e is ServerException) {
      return AuthException(AuthErrorType.server, 'เซิร์ฟเวอร์ขัดข้อง: ${e.message}');
    }
    return const AuthException(AuthErrorType.unknown, 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ');
  }
}
