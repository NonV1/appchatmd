// lib/core/data/user_repo.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/http_client.dart';
import '../user/session.dart';
import '../models/user_profile.dart';

/// คีย์เก็บ draft โปรไฟล์ไว้ชั่วคราว (เช่น ตอนกรอก onboarding แล้วยังไม่ submit)
class _DraftKeys {
  static const profile = 'draft.user_profile.json';
  static const conditions = 'draft.conditions.json';
}

/// Repo สำหรับข้อมูลผู้ใช้:
/// - ดึง/บันทึกโปรไฟล์จากแบ็กเอนด์
/// - อ่าน/เขียน “ภาวะ/โรคประจำตัว (conditions)”
/// - เก็บ draft ไว้โลคัล (เผื่อยังไม่ออนไลน์/ยังไม่กดยืนยัน)
class UserRepo {
  UserRepo({
    required ApiClient api,
    required Session session,
    FlutterSecureStorage? storage,
  })  : _api = api,
        _session = session,
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final ApiClient _api;
  final Session _session;
  final FlutterSecureStorage _storage;

  UserProfile? _profileCache;
  List<String>? _conditionsCache;

  /// ดึงโปรไฟล์จากแคช → ถ้าไม่มีค่อยยิง API → ถ้า API ไม่พร้อม ลองอ่าน draft
  Future<UserProfile?> fetchProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _profileCache != null) return _profileCache;

    try {
      final res = await _api.get('/me'); // ถ้าแบ็กเอนด์ยังไม่มี /me จะได้ 404
      if (res is Map<String, dynamic>) {
        _profileCache = UserProfile.fromJson(res);
        return _profileCache;
      }
      // ไม่ใช่ Map ให้ลองดึง /profile เป็น fallback
      final res2 = await _api.get('/profile');
      if (res2 is Map<String, dynamic>) {
        _profileCache = UserProfile.fromJson(res2);
        return _profileCache;
      }
    } on BadRequestException {
      // 404/400 → ไม่มี endpoint นี้
    } on UnauthorizedException {
      rethrow; // ให้ชั้นบนจัดการ logout/redirect
    } catch (_) {
      // เครือข่ายล่ม/เซิร์ฟเวอร์ล่ม → ไปลองอ่าน draft
    }

    // ลอง draft (ถ้ามี)
    final draftStr = await _storage.read(key: _DraftKeys.profile);
    if (draftStr != null && draftStr.isNotEmpty) {
      try {
        final m = jsonDecode(draftStr) as Map<String, dynamic>;
        _profileCache = UserProfile.fromJson(m);
        return _profileCache;
      } catch (_) {}
    }
    return null;
  }

  /// บันทึกโปรไฟล์ขึ้นเซิร์ฟเวอร์ (ถ้ามีอินเทอร์เน็ต) และอัปเดตแคช
  /// ถ้าออฟไลน์ → เซฟลง draft ก่อน
  Future<UserProfile> saveProfile(UserProfile profile) async {
    // เก็บ draft ไว้ก่อนเสมอ เผื่อเน็ตล่ม
    await _storage.write(
      key: _DraftKeys.profile,
      value: jsonEncode(profile.toJson()),
    );

    try {
      final res = await _api.put('/profile', body: profile.toJson());
      if (res is Map<String, dynamic>) {
        _profileCache = UserProfile.fromJson(res);
      } else {
        // ถ้าเซิร์ฟเวอร์ยังไม่คืน object โปรไฟล์ กลับมาใช้ของเดิม
        _profileCache = profile;
      }
      // เคลียร์ draft เมื่อบันทึกสำเร็จ
      await _storage.delete(key: _DraftKeys.profile);
      // อัปเดตชื่อแสดงผลใน Session (ถ้ามี)
      if (_profileCache?.displayName != null) {
        await _session.saveDisplayName(_profileCache!.displayName);
      }
      return _profileCache!;
    } on UnauthorizedException {
      rethrow; // ให้ชั้นบนพาไปล็อกอิน
    } on ApiException {
      // เซิร์ฟเวอร์ล่มหรือเน็ตล่ม → ใช้ draft ไปก่อน
      _profileCache = profile;
      return profile;
    }
  }

  /// อ่านรายการ “โรค/ภาวะ” ของผู้ใช้ (เช่น ["diabetes", "hypertension"])
  /// ลอง API → ถ้าไม่ได้ลอง draft
  Future<List<String>> fetchConditions({bool forceRefresh = false}) async {
    if (!forceRefresh && _conditionsCache != null) return _conditionsCache!;

    try {
      final res = await _api.get('/profile/conditions');
      if (res is List) {
        _conditionsCache =
            res.whereType<String>().toList(growable: false);
        return _conditionsCache!;
      }
    } on ApiException {
      // ลอง draft ต่อ
    }

    final draft = await _storage.read(key: _DraftKeys.conditions);
    if (draft != null && draft.isNotEmpty) {
      try {
        final list = (jsonDecode(draft) as List).whereType<String>().toList();
        _conditionsCache = list;
        return list;
      } catch (_) {}
    }

    _conditionsCache = const [];
    return _conditionsCache!;
  }

  /// ตั้งค่ารายการ “โรค/ภาวะ” และบันทึก
  Future<List<String>> saveConditions(List<String> conditions) async {
    // เก็บ draft ทันที
    await _storage.write(
      key: _DraftKeys.conditions,
      value: jsonEncode(conditions),
    );

    try {
      final res = await _api.put('/profile/conditions', body: {
        'conditions': conditions,
      });
      if (res is List) {
        _conditionsCache =
            res.whereType<String>().toList(growable: false);
      } else {
        _conditionsCache = conditions;
      }
      // เคลียร์ draft เมื่อสำเร็จ
      await _storage.delete(key: _DraftKeys.conditions);
      return _conditionsCache!;
    } on UnauthorizedException {
      rethrow;
    } on ApiException {
      // ออฟไลน์/ล่ม → เก็บไว้ใน draft + แคชไปก่อน
      _conditionsCache = conditions;
      return conditions;
    }
  }

  /// ยอมรับนโยบาย/เงื่อนไข (เก็บสถานะฝั่งเซิร์ฟเวอร์ ถ้ามี)
  Future<void> acceptPolicies({
    required bool acceptPrivacy,
    required bool acceptTerms,
  }) async {
    try {
      await _api.post('/profile/accept_policies', body: {
        'privacy': acceptPrivacy,
        'terms': acceptTerms,
      });
    } on ApiException {
      // ไม่ถือเป็น critical — ให้ UI จัดการรีทรายภายหลังได้
    }
  }

  /// ลบ draft ทั้งหมด (ใช้เมื่อผู้ใช้ยืนยันข้อมูลแล้ว)
  Future<void> clearDrafts() async {
    await _storage.delete(key: _DraftKeys.profile);
    await _storage.delete(key: _DraftKeys.conditions);
  }

  /// สำหรับ debug/วัดผล: คืนสรุปสถานะที่แอปใช้ได้
  Map<String, dynamic> debugSnapshot() => {
        'email': _session.cachedEmail,
        'displayName': _session.cachedDisplayName,
        'hasToken': _session.cachedToken != null,
        'profileCached': _profileCache?.toJson(),
        'conditionsCached': _conditionsCache,
      };
}
