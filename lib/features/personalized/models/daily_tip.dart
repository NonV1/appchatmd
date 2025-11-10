// lib/features/personalized/models/daily_tip.dart
import 'package:flutter/foundation.dart';

/// คำแนะนำสั้น ๆ ประจำวัน (ไม่ผูกกับ rule)
/// ใช้แสดงใน "For You" หรือแบนเนอร์/การ์ดทั่วไป
@immutable
class DailyTip {
  DailyTip({
    required this.id,              // unique id
    required this.title,           // หัวข้อ
    required this.body,            // เนื้อหา (สั้น)
    this.iconCodePoint,            // ไอคอน Material (เช่น Icons.tips_and_updates.codePoint)
    this.routeName,                // แตะแล้วไปหน้าไหน (ออปชัน)
    this.tags = const <String>[],  // จัดกลุ่ม เช่น ['general','sleep']
    this.locale,                   // 'th' | 'en' (ถ้ามีหลายภาษา)
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String body;
  final int? iconCodePoint;
  final String? routeName;
  final List<String> tags;
  final String? locale;
  final DateTime createdAt;

  DailyTip copyWith({
    String? id,
    String? title,
    String? body,
    int? iconCodePoint,
    String? routeName,
    List<String>? tags,
    String? locale,
    DateTime? createdAt,
  }) {
    return DailyTip(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      routeName: routeName ?? this.routeName,
      tags: tags ?? this.tags,
      locale: locale ?? this.locale,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        if (iconCodePoint != null) 'icon': iconCodePoint,
        if (routeName != null) 'route': routeName,
        'tags': tags,
        if (locale != null) 'locale': locale,
        'created_at': createdAt.toIso8601String(),
      };

  factory DailyTip.fromJson(Map<String, dynamic> m) {
    return DailyTip(
      id: (m['id'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      body: (m['body'] ?? '').toString(),
      iconCodePoint: (m['icon'] as int?),
      routeName: m['route'] as String?,
      tags: (m['tags'] as List? ?? const []).whereType<String>().toList(),
      locale: m['locale'] as String?,
      createdAt: DateTime.tryParse((m['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
