// lib/core/user/session.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// คีย์ที่ใช้เก็บข้อมูลใน Secure Storage
class _Keys {
  static const accessToken = 'session.access_token';
  static const email = 'session.email';
  static const displayName = 'session.display_name';
  static const locale = 'session.locale'; // 'th' | 'en' | etc.
  static const reduceMotion = 'prefs.reduce_motion'; // ✅ เปิด/ปิดแอนิเมชัน
}

/// Session = ศูนย์กลางสถานะผู้ใช้ฝั่งไคลเอนต์
/// - เก็บ token/email/displayName ใน SecureStorage
/// - เก็บ prefs ลดแอนิเมชัน (ไม่ลบทิ้งตอน logout)
/// - มี cache ในหน่วยความจำสำหรับอ่านเร็ว
/// - แจ้งเตือน UI ผ่าน ChangeNotifier (เหมาะกับ go_router.redirect)
class Session extends ChangeNotifier {
  Session({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static Session? _instance;

  /// Singleton แบบ lazy (ใช้ร่วมกับ main.dart)
  static Session get I => _instance ??= Session();
  static Session get instance => I;

  final FlutterSecureStorage _storage;

  String? _token;
  String? _email;
  String? _displayName;
  String _locale = 'en'; // ค่าเริ่มต้น

  /// ลดแอนิเมชันทั้งแอป (prefs) — ค่าเริ่มต้น false
  bool _reduceMotion = false;

  /// expose ค่า cache สำหรับตรวจเงื่อนไขเร็ว ๆ
  String? get cachedToken => _token;
  String? get cachedEmail => _email;
  String? get cachedDisplayName => _displayName;
  String get localeCode => _locale;

  /// ใส่ไว้ให้ Theme/Animation layer อ่านได้ทันที
  bool get reduceMotion => _reduceMotion;

  /// ให้ router ใช้เป็น Listenable ได้สะดวก
  Listenable get listenable => this;

  /// โหลดค่าเริ่มต้นจาก SecureStorage (เรียกครั้งเดียวตอนบูต)
  Future<void> init() async {
    _token = await _storage.read(key: _Keys.accessToken);
    _email = await _storage.read(key: _Keys.email);
    _displayName = await _storage.read(key: _Keys.displayName);
    _locale = await _storage.read(key: _Keys.locale) ?? _locale;

    final rm = await _storage.read(key: _Keys.reduceMotion);
    _reduceMotion = (rm == '1' || rm?.toLowerCase() == 'true');

    notifyListeners();
  }

  /// alias เพื่อให้ main.dart อ่านสั้น ๆ
  Future<void> hydrate() => init();

  /// helper ให้ HttpClient เรียกผ่าน TokenProvider
  Future<String?> getToken() => readAccessToken();

  /// อ่าน token ปัจจุบัน (ดึงจาก cache ถ้ามี)
  Future<String?> readAccessToken() async {
    _token ??= await _storage.read(key: _Keys.accessToken);
    return _token;
  }

  Future<void> saveAccessToken(String token) async {
    _token = token;
    await _storage.write(key: _Keys.accessToken, value: token);
    notifyListeners();
  }

  Future<String?> readEmail() async {
    _email ??= await _storage.read(key: _Keys.email);
    return _email;
  }

  Future<void> saveEmail(String email) async {
    _email = email;
    await _storage.write(key: _Keys.email, value: email);
    notifyListeners();
  }

  Future<String?> readDisplayName() async {
    _displayName ??= await _storage.read(key: _Keys.displayName);
    return _displayName;
  }

  Future<void> saveDisplayName(String? name) async {
    _displayName = name;
    if (name == null) {
      await _storage.delete(key: _Keys.displayName);
    } else {
      await _storage.write(key: _Keys.displayName, value: name);
    }
    notifyListeners();
  }

  /// เปลี่ยนภาษา (เก็บไว้ใช้ตอนบูตแอปเพื่อเลือก locale)
  Future<void> setLocale(String code) async {
    _locale = code;
    await _storage.write(key: _Keys.locale, value: code);
    notifyListeners();
  }

  /// เปิด/ปิดลดแอนิเมชันทั้งแอป (กระทบธีม/เอฟเฟกต์)
  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    await _storage.write(key: _Keys.reduceMotion, value: value ? '1' : '0');
    notifyListeners();
  }

  Future<void> toggleReduceMotion() => setReduceMotion(!_reduceMotion);

  /// ล้างข้อมูลผู้ใช้ (logout) — *ไม่* ลบ reduceMotion/locale เพื่อคงค่า prefs
  Future<void> clear() async {
    _token = null;
    _email = null;
    _displayName = null;

    await _storage.delete(key: _Keys.accessToken);
    await _storage.delete(key: _Keys.email);
    await _storage.delete(key: _Keys.displayName);

    notifyListeners();
  }
}
