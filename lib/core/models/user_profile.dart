// lib/core/models/user_profile.dart
import 'dart:math';

/// โปรไฟล์ผู้ใช้แบบยืดหยุ่น (ไม่พึ่ง codegen)
/// - เก็บข้อมูลพื้นฐาน: ชื่อ อีเมล เพศ วันเกิด ส่วนสูง/น้ำหนัก แพ้ยา โรคประจำตัว
/// - สถานะยอมรับนโยบาย
/// - thresholds เฉพาะบุคคล (เช่น ค่าหัวใจสูงสุดที่อยากแจ้งเตือน)
class UserProfile {
  final String? id;                // เผื่อ sync กับฝั่งเซิร์ฟเวอร์
  final String? displayName;
  final String? email;

  /// 'male' | 'female' | 'other' | null
  final String? gender;

  /// เก็บเป็น ISO-8601 (yyyy-MM-dd) เพื่อความง่าย (ฝั่ง UI แปลงเป็น DateTime ได้)
  final String? birthDate;         // ตัวอย่าง "2001-04-10"

  final double? heightCm;          // ส่วนสูง (ซม.)
  final double? weightKg;          // น้ำหนัก (กก.)

  final List<String> allergies;    // แพ้ยา/อาหาร
  final List<String> conditions;   // โรคประจำตัว เช่น ['diabetes', 'hypertension']

  /// นโยบาย/ข้อตกลง
  final bool acceptedPrivacy;
  final bool acceptedTerms;

  /// ค่ากำหนดเฉพาะบุคคล (ยืดหยุ่น—กำหนดเป็น key-value)
  /// ตัวอย่าง:
  ///   { "hr.max_warn": 130, "hr.min_warn": 45, "sleep.min_hours": 6 }
  final Map<String, num> thresholds;

  /// เวอร์ชันข้อมูล (ช่วยแก้ปัญหาการแปลง schema ในอนาคต)
  final int schemaVersion;

  const UserProfile({
    this.id,
    this.displayName,
    this.email,
    this.gender,
    this.birthDate,
    this.heightCm,
    this.weightKg,
    this.allergies = const [],
    this.conditions = const [],
    this.acceptedPrivacy = false,
    this.acceptedTerms = false,
    this.thresholds = const {},
    this.schemaVersion = 1,
  });

  /// ช่วยให้แก้บางฟิลด์ได้ง่าย (ไม่ต้องสร้างใหม่ทั้งหมด)
  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? gender,
    String? birthDate,
    double? heightCm,
    double? weightKg,
    List<String>? allergies,
    List<String>? conditions,
    bool? acceptedPrivacy,
    bool? acceptedTerms,
    Map<String, num>? thresholds,
    int? schemaVersion,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      thresholds: thresholds ?? this.thresholds,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  /// ฟังก์ชันช่วยคำนวณ
  double? get bmi {
    if (heightCm == null || heightCm == 0 || weightKg == null) return null;
    final h = (heightCm! / 100.0);
    return (weightKg! / pow(h, 2));
  }

  /// อายุคร่าว ๆ (ถ้า birthDate เป็น yyyy-MM-dd)
  int? get age {
    final dt = _tryParseDate(birthDate);
    if (dt == null) return null;
    final now = DateTime.now();
    int a = now.year - dt.year;
    final hadBirthdayThisYear =
        (now.month > dt.month) || (now.month == dt.month && now.day >= dt.day);
    return hadBirthdayThisYear ? a : a - 1;
  }

  /// ใช้ตรวจว่า “ข้อมูลพื้นฐานครบระดับขั้นต่ำ” หรือยัง (ไว้บังคับใน onboarding)
  bool get isMinimumComplete =>
      (displayName?.isNotEmpty == true) &&
      (email?.isNotEmpty == true) &&
      acceptedPrivacy &&
      acceptedTerms;

  /// แปลง JSON → โมเดล (null-safe และทน schema ต่าง ๆ)
  factory UserProfile.fromJson(Map<String, dynamic> m) {
    List<String> stringList(dynamic v) {
      if (v is List) return v.whereType<String>().toList();
      return const [];
    }

    Map<String, num> numMap(dynamic v) {
      if (v is Map) {
        final out = <String, num>{};
        v.forEach((k, val) {
          if (k is String) {
            if (val is num) out[k] = val;
            if (val is String) {
              final parsed = num.tryParse(val);
              if (parsed != null) out[k] = parsed;
            }
          }
        });
        return out;
      }
      return const {};
    }

    double? toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return UserProfile(
      id: _asString(m['id'] ?? m['uuid']),
      displayName: _asString(m['display_name'] ?? m['name']),
      email: _asString(m['email']),
      gender: _asString(m['gender']),
      birthDate: _asString(m['birth_date'] ?? m['dob']),
      heightCm: toDouble(m['height_cm'] ?? m['height']),
      weightKg: toDouble(m['weight_kg'] ?? m['weight']),
      allergies: stringList(m['allergies']),
      conditions: stringList(m['conditions']),
      acceptedPrivacy: _asBool(m['accepted_privacy']),
      acceptedTerms: _asBool(m['accepted_terms']),
      thresholds: numMap(m['thresholds']),
      schemaVersion: _asInt(m['schema_version']) ?? 1,
    );
  }

  /// แปลงเป็น JSON (พร้อมสำหรับส่งไปแบ็กเอนด์ / เก็บ draft)
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'display_name': displayName,
        'email': email,
        'gender': gender,
        'birth_date': birthDate,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'allergies': allergies,
        'conditions': conditions,
        'accepted_privacy': acceptedPrivacy,
        'accepted_terms': acceptedTerms,
        'thresholds': thresholds,
        'schema_version': schemaVersion,
      };

  /// รวมโปรไฟล์ A ทับด้วย B (ใช้กับ draft → server หรือ merge partial updates)
  UserProfile merge(UserProfile other) {
    return copyWith(
      id: other.id ?? id,
      displayName: other.displayName ?? displayName,
      email: other.email ?? email,
      gender: other.gender ?? gender,
      birthDate: other.birthDate ?? birthDate,
      heightCm: other.heightCm ?? heightCm,
      weightKg: other.weightKg ?? weightKg,
      allergies: other.allergies.isNotEmpty ? other.allergies : allergies,
      conditions: other.conditions.isNotEmpty ? other.conditions : conditions,
      acceptedPrivacy: other.acceptedPrivacy || acceptedPrivacy,
      acceptedTerms: other.acceptedTerms || acceptedTerms,
      thresholds: other.thresholds.isNotEmpty ? other.thresholds : thresholds,
      schemaVersion: max(schemaVersion, other.schemaVersion),
    );
  }

  /// -------- helpers --------
  static String? _asString(dynamic v) => (v is String && v.isNotEmpty) ? v : null;
  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  static DateTime? _tryParseDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }
}
