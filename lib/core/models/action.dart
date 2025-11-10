// lib/core/models/action.dart
import 'package:flutter/foundation.dart';

/// สเปกของ "แอคชัน" ที่จะถูกยิงเมื่อกติกาถูกทริกเกอร์
///
/// ไม่ผูกกับแพลตฟอร์ม: ตัว Engine ฝั่งแอปจะเป็นผู้ตีความ
///   - type:
///       'notify'        → ส่งการแจ้งเตือนภายในแอป/ระบบ
///       'surface_card'  → ดันการ์ดขึ้นในพื้นที่ "เฉพาะคุณ" หรือโซนที่กำหนด
///       'open_route'    → นำทางไปยังเส้นทางในแอป (เช่น '/wearables')
///       'log'           → เก็บบันทึกเหตุการณ์ (เพื่อวิเคราะห์ทีหลัง)
///   - title/body: ใช้กับ notify หรือแสดงบน UI ตามชนิดแอคชัน
///   - payload: พารามิเตอร์เสริม (เช่น { 'feature_id': 'for_you', 'card_id': 'for_you.hr_watch' })
@immutable
class ActionSpec {
  const ActionSpec({
    required this.type,
    this.title,
    this.body,
    this.payload,
  });

  /// ประเภทแอคชัน (อิสระแต่แนะนำใช้คำที่ระบุด้านบน)
  final String type;

  /// ข้อความหัวเรื่อง (ถ้ามี)
  final String? title;

  /// เนื้อความ (ถ้ามี)
  final String? body;

  /// พารามิเตอร์เพิ่มเติม (เช่น { 'route': '/wearables', 'args': {...} })
  final Map<String, dynamic>? payload;

  /// ---- Factory helpers (ให้อ่าน/เขียนสั้นลง) ----

  /// แจ้งเตือนทั่วไป
  factory ActionSpec.notify({
    required String title,
    String? body,
    Map<String, dynamic>? payload,
  }) =>
      ActionSpec(type: 'notify', title: title, body: body, payload: payload);

  /// ผลักการ์ดขึ้นในโซนที่กำหนด (เช่น “เฉพาะคุณ”)
  factory ActionSpec.surfaceCard({
    required String featureId,
    required String cardId,
    Map<String, dynamic>? extra,
  }) =>
      ActionSpec(
        type: 'surface_card',
        payload: {
          'feature_id': featureId,
          'card_id': cardId,
          if (extra != null) ...extra,
        },
      );

  /// เปิดเส้นทางภายในแอป (เช่น ไปหน้า '/wearables')
  factory ActionSpec.openRoute({
    required String route,
    Map<String, dynamic>? args,
  }) =>
      ActionSpec(
        type: 'open_route',
        payload: {
          'route': route,
          if (args != null) 'args': args,
        },
      );

  /// บันทึกเหตุการณ์ (สำหรับ debug/analytics)
  factory ActionSpec.log({
    String? title,
    String? body,
    Map<String, dynamic>? data,
  }) =>
      ActionSpec(
        type: 'log',
        title: title,
        body: body,
        payload: data,
      );

  /// ---- JSON ----
  Map<String, dynamic> toJson() => {
        'type': type,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (payload != null) 'payload': payload,
      };

  factory ActionSpec.fromJson(Map<String, dynamic> m) => ActionSpec(
        type: (m['type'] ?? '').toString(),
        title: m['title'] as String?,
        body: m['body'] as String?,
        payload: (m['payload'] as Map?)?.cast<String, dynamic>(),
      );

  /// สะดวกเวลา copy พร้อมแก้บางฟิลด์
  ActionSpec copyWith({
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? payload,
  }) {
    return ActionSpec(
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
    );
    }
}
