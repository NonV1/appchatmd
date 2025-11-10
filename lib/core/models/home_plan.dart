// lib/core/models/home_plan.dart

import 'package:flutter/foundation.dart';

/// ฟีเจอร์บนหน้า Home (อ้างอิงด้วย id string เพื่อหลีกเลี่ยงการผูก enum ข้ามแพ็กเกจ)
class FeatureIds {
  static const wearable = 'wearable';
  static const aiChat = 'ai_chat';
  static const aiDisease = 'ai_disease';
  static const food = 'food';
  static const fitness = 'fitness';
  static const doctor = 'doctor';
  static const feed = 'feed';
  static const settings = 'settings';
  static const quickPanel = 'quick_panel';
  static const forYou = 'for_you'; // หมวด “เฉพาะคุณ”
}

/// ขนาดการ์ดเป็นหน่วยกริด (เช่น 1x1, 2x1, 2x2)
@immutable
class GridSize {
  const GridSize(this.w, this.h)
      : assert(w > 0 && h > 0, 'grid size must be positive');
  final int w;
  final int h;

  Map<String, dynamic> toJson() => {'w': w, 'h': h};
  factory GridSize.fromJson(Map<String, dynamic> m) =>
      GridSize((m['w'] ?? 1) as int, (m['h'] ?? 1) as int);
}

/// การ์ด 1 ใบบนหน้า Home
@immutable
class HomeCardSpec {
  const HomeCardSpec({
    required this.id,                // unique ภายในแผน
    required this.featureId,         // อ้างอิง FeatureIds
    required this.title,             // ข้อความบนการ์ด (แปลภายหลัง)
    this.subtitle,
    this.metricIds = const <String>[], // metric ที่การ์ดนี้จะแสดง (id-based)
    this.size = const GridSize(1, 1),
    this.priority = 100,             // เลขน้อย = อยู่บน/ซ้ายก่อน
    this.pinned = false,             // true = อยู่ตำแหน่งเดิมเสมอ
    this.visible = true,             // เปิด/ปิดการ์ด
    this.payload,                    // ข้อมูลเฉพาะ (เช่น คิวรีกราฟ, ฟิลเตอร์)
  });

  final String id;
  final String featureId;
  final String title;
  final String? subtitle;
  final List<String> metricIds;
  final GridSize size;
  final int priority;
  final bool pinned;
  final bool visible;
  final Map<String, dynamic>? payload;

  HomeCardSpec copyWith({
    String? id,
    String? featureId,
    String? title,
    String? subtitle,
    List<String>? metricIds,
    GridSize? size,
    int? priority,
    bool? pinned,
    bool? visible,
    Map<String, dynamic>? payload,
  }) {
    return HomeCardSpec(
      id: id ?? this.id,
      featureId: featureId ?? this.featureId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      metricIds: metricIds ?? this.metricIds,
      size: size ?? this.size,
      priority: priority ?? this.priority,
      pinned: pinned ?? this.pinned,
      visible: visible ?? this.visible,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'feature_id': featureId,
        'title': title,
        'subtitle': subtitle,
        'metric_ids': metricIds,
        'size': size.toJson(),
        'priority': priority,
        'pinned': pinned,
        'visible': visible,
        if (payload != null) 'payload': payload,
      };

  factory HomeCardSpec.fromJson(Map<String, dynamic> m) => HomeCardSpec(
        id: (m['id'] ?? '').toString(),
        featureId: (m['feature_id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        subtitle: (m['subtitle'] as String?),
        metricIds: (m['metric_ids'] as List?)?.whereType<String>().toList() ?? const [],
        size: m['size'] is Map<String, dynamic>
            ? GridSize.fromJson(m['size'] as Map<String, dynamic>)
            : const GridSize(1, 1),
        priority: (m['priority'] as int?) ?? 100,
        pinned: (m['pinned'] as bool?) ?? false,
        visible: (m['visible'] as bool?) ?? true,
        payload: (m['payload'] as Map?)?.cast<String, dynamic>(),
      );
}

/// Section = กล่องรวมการ์ด (เช่น “สรุปวันนี้”, “เฉพาะคุณ”, “แนะนำ”)
@immutable
class HomeSection {
  const HomeSection({
    required this.id,       // unique ในแผน
    required this.title,    // ชื่อ section (แปลภายหลัง)
    required this.items,    // list ของการ์ด
    this.priority = 100,    // section เล็กน้อยอยู่ล่าง
    this.visible = true,
  });

  final String id;
  final String title;
  final List<HomeCardSpec> items;
  final int priority;
  final bool visible;

  HomeSection copyWith({
    String? id,
    String? title,
    List<HomeCardSpec>? items,
    int? priority,
    bool? visible,
  }) {
    return HomeSection(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items ?? this.items,
      priority: priority ?? this.priority,
      visible: visible ?? this.visible,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority,
        'visible': visible,
        'items': items.map((e) => e.toJson()).toList(growable: false),
      };

  factory HomeSection.fromJson(Map<String, dynamic> m) => HomeSection(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        priority: (m['priority'] as int?) ?? 100,
        visible: (m['visible'] as bool?) ?? true,
        items: (m['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => HomeCardSpec.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false),
      );
}

/// แผนรวมทั้งหมดของหน้า Home (จัดลำดับ section + การ์ด)
@immutable
class HomePlan {
  const HomePlan({
    required this.version,        // schema version เผื่ออนาคต
    required this.sections,
    this.quickActions = const [], // ปุ่มด่วน (กลางล่าง/แถบด้านล่าง)
    this.createdAt,
  });

  final int version;
  final List<HomeSection> sections;
  final List<QuickAction> quickActions;
  final DateTime? createdAt;

  HomePlan copyWith({
    int? version,
    List<HomeSection>? sections,
    List<QuickAction>? quickActions,
    DateTime? createdAt,
  }) {
    return HomePlan(
      version: version ?? this.version,
      sections: sections ?? this.sections,
      quickActions: quickActions ?? this.quickActions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// รวม/สลับ section โดยเรียงตาม priority
  List<HomeSection> get orderedSections {
    final list = sections.where((s) => s.visible).toList(growable: false)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return list;
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
        'sections': sections.map((e) => e.toJson()).toList(growable: false),
        'quick_actions': quickActions.map((e) => e.toJson()).toList(growable: false),
      };

  factory HomePlan.fromJson(Map<String, dynamic> m) => HomePlan(
        version: (m['version'] as int?) ?? 1,
        createdAt: _parseDt(m['created_at']),
        sections: (m['sections'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => HomeSection.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false),
        quickActions: (m['quick_actions'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => QuickAction.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false),
      );

  /// ---------- แผนตัวอย่างพร้อมใช้ ----------

  /// แผนมาตรฐาน (ผู้ใช้ทั่วไป)
  factory HomePlan.standard() {
    return HomePlan(
      version: 1,
      createdAt: DateTime.now(),
      quickActions: const [
        QuickAction(id: 'qa.quick_panel', featureId: FeatureIds.quickPanel, label: 'Quick'),
        QuickAction(id: 'qa.ai_chat', featureId: FeatureIds.aiChat, label: 'Ask AI'),
      ],
      sections: [
        HomeSection(
          id: 'summary',
          title: 'Today summary',
          priority: 10,
          items: const [
            HomeCardSpec(
              id: 'wear.steps',
              featureId: FeatureIds.wearable,
              title: 'Steps',
              metricIds: ['steps'],
              size: GridSize(2, 1),
              priority: 1,
              pinned: true,
            ),
            HomeCardSpec(
              id: 'wear.hr',
              featureId: FeatureIds.wearable,
              title: 'Heart rate',
              metricIds: ['heart_rate'],
              size: GridSize(1, 1),
              priority: 2,
            ),
            HomeCardSpec(
              id: 'wear.sleep',
              featureId: FeatureIds.wearable,
              title: 'Sleep',
              metricIds: ['sleep_sec'],
              size: GridSize(1, 1),
              priority: 3,
            ),
            HomeCardSpec(
              id: 'ai.chat',
              featureId: FeatureIds.aiChat,
              title: 'AI doctor',
              subtitle: 'Ask anything',
              size: GridSize(2, 1),
              priority: 4,
            ),
          ],
        ),
        HomeSection(
          id: 'explore',
          title: 'Explore',
          priority: 20,
          items: const [
            HomeCardSpec(
              id: 'food',
              featureId: FeatureIds.food,
              title: 'Food',
              size: GridSize(1, 1),
              priority: 1,
            ),
            HomeCardSpec(
              id: 'fitness',
              featureId: FeatureIds.fitness,
              title: 'Fitness',
              size: GridSize(1, 1),
              priority: 2,
            ),
            HomeCardSpec(
              id: 'ai.disease',
              featureId: FeatureIds.aiDisease,
              title: 'AI disease',
              size: GridSize(2, 1),
              priority: 3,
            ),
          ],
        ),
      ],
    );
  }

  /// แผน “เฉพาะคุณ” (ตัวอย่าง: ผู้ใช้มีภาวะเบาหวาน)
  HomePlan withDiabetesHints() {
    // แทรก section เฉพาะคุณ ด้านบนของ explore (priority ต่ำกว่า summary)
    final sx = List<HomeSection>.from(sections);
    final hasForYou = sx.any((s) => s.id == FeatureIds.forYou);
    if (!hasForYou) {
      sx.add(const HomeSection(
        id: FeatureIds.forYou,
        title: 'For you',
        priority: 15,
        items: [
          HomeCardSpec(
            id: 'for_you.hr_watch',
            featureId: FeatureIds.wearable,
            title: 'Watch your HR',
            subtitle: 'Keep a steady pace',
            metricIds: ['heart_rate'],
            size: GridSize(2, 1),
            priority: 1,
          ),
          HomeCardSpec(
            id: 'for_you.sleep_hygiene',
            featureId: FeatureIds.wearable,
            title: 'Sleep hygiene',
            subtitle: 'Aim for 7–8h',
            metricIds: ['sleep_sec'],
            size: GridSize(1, 1),
            priority: 2,
          ),
          HomeCardSpec(
            id: 'for_you.food_tips',
            featureId: FeatureIds.food,
            title: 'Food tips',
            subtitle: 'Low-GI picks',
            size: GridSize(1, 1),
            priority: 3,
          ),
        ],
      ));
    }
    return copyWith(sections: sx);
  }

  static DateTime? _parseDt(dynamic v) {
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    return null;
  }
}

/// ปุ่มด่วน (เช่น ปุ่มตรงกลางล่างเพื่อเปิด Quick Panel)
@immutable
class QuickAction {
  const QuickAction({
    required this.id,
    required this.featureId, // เปิดไปยังฟีเจอร์ไหน
    required this.label,
    this.payload,
  });

  final String id;
  final String featureId;
  final String label;
  final Map<String, dynamic>? payload;

  Map<String, dynamic> toJson() => {
        'id': id,
        'feature_id': featureId,
        'label': label,
        if (payload != null) 'payload': payload,
      };

  factory QuickAction.fromJson(Map<String, dynamic> m) => QuickAction(
        id: (m['id'] ?? '').toString(),
        featureId: (m['feature_id'] ?? '').toString(),
        label: (m['label'] ?? '').toString(),
        payload: (m['payload'] as Map?)?.cast<String, dynamic>(),
      );
}
