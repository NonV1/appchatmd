// lib/core/models/notification_item.dart
import 'package:flutter/foundation.dart';

/// ระดับความสำคัญของการแจ้งเตือน (อิสระจาก Severity ใน rule.dart เพื่อลด coupling)
enum NotificationLevel { info, warning, critical }

/// แหล่งที่มาของการแจ้งเตือน (ไว้ debug/กรอง)
@immutable
class NotificationSource {
  final String? ruleId;     // ถ้ามาจากกติกา → ใส่ id
  final String? featureId;  // เช่น 'wearables', 'for_you', 'ai_disease'
  final String? origin;     // ข้อความสั้น ๆ เช่น 'engine', 'server', 'manual'

  const NotificationSource({this.ruleId, this.featureId, this.origin});

  Map<String, dynamic> toJson() => {
        if (ruleId != null) 'rule_id': ruleId,
        if (featureId != null) 'feature_id': featureId,
        if (origin != null) 'origin': origin,
      };

  factory NotificationSource.fromJson(Map<String, dynamic> m) =>
      NotificationSource(
        ruleId: m['rule_id'] as String?,
        featureId: m['feature_id'] as String?,
        origin: m['origin'] as String?,
      );
}

/// โมเดลรายการแจ้งเตือนหนึ่งรายการ
@immutable
class NotificationItem {
  final String id;                 // unique (uuid)
  final String title;              // หัวเรื่อง
  final String? body;              // เนื้อความยาว
  final NotificationLevel level;   // ระดับความสำคัญ

  final DateTime createdAt;        // เวลาเกิดเหตุ
  final DateTime? readAt;          // เวลาอ่าน (null = ยังไม่อ่าน)
  final DateTime? expiresAt;       // หมดอายุ/เลิกแสดงอัตโนมัติ (ถ้ามี)

  /// ทำให้อยู่ด้านบน (เช่น banner สำคัญ)
  final bool sticky;

  /// ไม่เด้งเสียง/สั่น (แจ้งเตือนเงียบใน in-app)
  final bool silent;

  /// deep-link ภายในแอป (เช่น '/wearables' หรือ '/for-you/detail')
  final String? route;

  /// payload เพิ่มเติมให้หน้าปลายทาง (key-value)
  final Map<String, dynamic>? payload;

  /// อ้างอิงแหล่งที่มา (rule/feature/engine/server)
  final NotificationSource? source;

  const NotificationItem({
    required this.id,
    required this.title,
    this.body,
    this.level = NotificationLevel.info,
    required this.createdAt,
    this.readAt,
    this.expiresAt,
    this.sticky = false,
    this.silent = false,
    this.route,
    this.payload,
    this.source,
  });

  bool get isRead => readAt != null;
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  NotificationItem markRead([DateTime? when]) =>
      copyWith(readAt: when ?? DateTime.now());

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationLevel? level,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? expiresAt,
    bool? sticky,
    bool? silent,
    String? route,
    Map<String, dynamic>? payload,
    NotificationSource? source,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
      sticky: sticky ?? this.sticky,
      silent: silent ?? this.silent,
      route: route ?? this.route,
      payload: payload ?? this.payload,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (body != null) 'body': body,
        'level': level.name,
        'created_at': createdAt.toIso8601String(),
        if (readAt != null) 'read_at': readAt!.toIso8601String(),
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        'sticky': sticky,
        'silent': silent,
        if (route != null) 'route': route,
        if (payload != null) 'payload': payload,
        if (source != null) 'source': source!.toJson(),
      };

  factory NotificationItem.fromJson(Map<String, dynamic> m) => NotificationItem(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        body: m['body'] as String?,
        level: NotificationLevel.values.firstWhere(
          (e) => e.name == (m['level'] ?? 'info'),
          orElse: () => NotificationLevel.info,
        ),
        createdAt: DateTime.tryParse((m['created_at'] ?? '').toString()) ??
            DateTime.now(),
        readAt: m['read_at'] != null
            ? DateTime.tryParse(m['read_at'].toString())
            : null,
        expiresAt: m['expires_at'] != null
            ? DateTime.tryParse(m['expires_at'].toString())
            : null,
        sticky: (m['sticky'] as bool?) ?? false,
        silent: (m['silent'] as bool?) ?? false,
        route: m['route'] as String?,
        payload: (m['payload'] as Map?)?.cast<String, dynamic>(),
        source: m['source'] is Map
            ? NotificationSource.fromJson(
                (m['source'] as Map).cast<String, dynamic>())
            : null,
      );
}
