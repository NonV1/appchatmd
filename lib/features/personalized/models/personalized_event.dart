// lib/features/personalized/models/personalized_event.dart
import 'package:flutter/foundation.dart';

import '../../../core/models/rule.dart' show Severity;

/// แหล่งที่มาของเหตุการณ์ส่วนบุคคล
enum PEventSource { rule, tip, system }

/// อินสแตนซ์ “เหตุการณ์เฉพาะคุณ” ที่พร้อมจะไปแสดงบนการ์ด/อินบ็อกซ์
/// อาจมาจาก rule ที่ทริกเกอร์, daily tip, หรือ system message
@immutable
class PersonalizedEvent {
  PersonalizedEvent({
    required this.id,                 // unique id
    required this.source,             // rule | tip | system
    this.ruleId,                      // ถ้ามาจาก rule
    this.tipId,                       // ถ้ามาจาก tip
    required this.title,
    required this.subtitle,
    this.severity = Severity.info,    // ระดับความสำคัญ
    this.iconCodePoint,               // Material icon codePoint
    this.routeName,                   // แตะแล้วไปหน้าไหน
    this.payload,                     // ข้อมูลเพิ่ม (เช่น feature_id/card_id)
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final PEventSource source;
  final String? ruleId;
  final String? tipId;

  final String title;
  final String subtitle;
  final Severity severity;
  final int? iconCodePoint;
  final String? routeName;
  final Map<String, dynamic>? payload;

  final DateTime createdAt;

  PersonalizedEvent copyWith({
    String? id,
    PEventSource? source,
    String? ruleId,
    String? tipId,
    String? title,
    String? subtitle,
    Severity? severity,
    int? iconCodePoint,
    String? routeName,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
  }) {
    return PersonalizedEvent(
      id: id ?? this.id,
      source: source ?? this.source,
      ruleId: ruleId ?? this.ruleId,
      tipId: tipId ?? this.tipId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      severity: severity ?? this.severity,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      routeName: routeName ?? this.routeName,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source.name,
        if (ruleId != null) 'rule_id': ruleId,
        if (tipId != null) 'tip_id': tipId,
        'title': title,
        'subtitle': subtitle,
        'severity': severity.name,
        if (iconCodePoint != null) 'icon': iconCodePoint,
        if (routeName != null) 'route': routeName,
        if (payload != null) 'payload': payload,
        'created_at': createdAt.toIso8601String(),
      };

  factory PersonalizedEvent.fromJson(Map<String, dynamic> m) {
    final srcStr = (m['source'] ?? 'system').toString();
    final sevStr = (m['severity'] ?? 'info').toString();

    return PersonalizedEvent(
      id: (m['id'] ?? '').toString(),
      source: PEventSource.values.firstWhere(
        (e) => e.name == srcStr,
        orElse: () => PEventSource.system,
      ),
      ruleId: m['rule_id'] as String?,
      tipId: m['tip_id'] as String?,
      title: (m['title'] ?? '').toString(),
      subtitle: (m['subtitle'] ?? '').toString(),
      severity: Severity.values.firstWhere(
        (e) => e.name == sevStr,
        orElse: () => Severity.info,
      ),
      iconCodePoint: m['icon'] as int?,
      routeName: m['route'] as String?,
      payload: (m['payload'] as Map?)?.cast<String, dynamic>(),
      createdAt: DateTime.tryParse((m['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
