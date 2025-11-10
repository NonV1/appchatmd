// lib/core/models/rule.dart

import 'package:flutter/foundation.dart';
import 'package:chatmd_v1/core/models/action.dart' as act; // ✅ ใช้ ActionSpec จาก action.dart

/// รูปแบบการเปรียบเทียบ
enum CompareOp { gt, gte, lt, lte, eq, ne }

/// โหมดรวมเงื่อนไข
enum BoolOp { and, or }

/// ความรุนแรง/ความสำคัญของเหตุการณ์
enum Severity { info, warning, critical }

/// แหล่งที่มาของค่า threshold (ตอนนี้ใช้ค่าคงที่ไปก่อน)
@immutable
class ThresholdSource {
  const ThresholdSource.constant(this.value) : type = 'constant';
  final String type; // 'constant' | 'profile' | 'remote' (เผื่ออนาคต)
  final num value;

  Map<String, dynamic> toJson() => {'type': type, 'value': value};

  factory ThresholdSource.fromJson(Map<String, dynamic> m) {
    final t = (m['type'] ?? 'constant') as String;
    if (t == 'constant') {
      return ThresholdSource.constant((m['value'] ?? 0) as num);
    }
    // อนาคต: profile/remote
    return ThresholdSource.constant((m['value'] ?? 0) as num);
  }
}

/// เงื่อนไขแบบ “ใบไม้” เทียบ metric (เช่น heart_rate > 120)
@immutable
class MetricConditionLeaf {
  const MetricConditionLeaf({
    required this.metricId, // อ้างอิง MetricIds ใน wearable_metrics.dart
    required this.op,
    required this.threshold,
  });

  final String metricId;
  final CompareOp op;
  final ThresholdSource threshold;

  Map<String, dynamic> toJson() => {
        'type': 'metric',
        'metric_id': metricId,
        'op': op.name,
        'threshold': threshold.toJson(),
      };

  factory MetricConditionLeaf.fromJson(Map<String, dynamic> m) {
    return MetricConditionLeaf(
      metricId: (m['metric_id'] ?? '').toString(),
      op: CompareOp.values.firstWhere(
        (e) => e.name == (m['op'] ?? 'gt'),
        orElse: () => CompareOp.gt,
      ),
      threshold: ThresholdSource.fromJson(
        (m['threshold'] as Map?)?.cast<String, dynamic>() ?? const {'value': 0},
      ),
    );
  }

  bool evaluate(Map<String, num> metrics) {
    final v = metrics[metricId];
    if (v == null) return false;
    final t = threshold.value;
    switch (op) {
      case CompareOp.gt:
        return v > t;
      case CompareOp.gte:
        return v >= t;
      case CompareOp.lt:
        return v < t;
      case CompareOp.lte:
        return v <= t;
      case CompareOp.eq:
        return v == t;
      case CompareOp.ne:
        return v != t;
    }
  }
}

/// โหนดเงื่อนไขแบบซ้อน (AND/OR) หรือใบไม้
@immutable
class ConditionNode {
  const ConditionNode.leaf(this.leaf)
      : op = null,
        children = const [];

  const ConditionNode.group({
    required this.op,
    required this.children,
  }) : leaf = null;

  final BoolOp? op;
  final List<ConditionNode> children;
  final MetricConditionLeaf? leaf;

  Map<String, dynamic> toJson() {
    if (leaf != null) return leaf!.toJson();
    return {
      'type': 'group',
      'op': op!.name,
      'children': children.map((c) => c.toJson()).toList(growable: false),
    };
  }

  factory ConditionNode.fromJson(Map<String, dynamic> m) {
    final t = (m['type'] ?? 'metric') as String;
    if (t == 'metric') {
      return ConditionNode.leaf(MetricConditionLeaf.fromJson(m));
    }
    // group
    final op = BoolOp.values.firstWhere(
      (e) => e.name == (m['op'] ?? 'and'),
      orElse: () => BoolOp.and,
    );
    final children = (m['children'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => ConditionNode.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
    return ConditionNode.group(op: op, children: children);
  }

  /// ประเมินเงื่อนไขกับชุด metrics ปัจจุบัน
  bool evaluate(Map<String, num> metrics) {
    if (leaf != null) return leaf!.evaluate(metrics);
    if (children.isEmpty) return false;
    if (op == BoolOp.and) {
      for (final c in children) {
        if (!c.evaluate(metrics)) return false;
      }
      return true;
    } else {
      // OR
      for (final c in children) {
        if (c.evaluate(metrics)) return true;
      }
      return false;
    }
  }
}

// ❌ ลบคลาส ActionSpec เดิมทิ้งจากไฟล์นี้ (เราใช้ของจริงจาก action.dart เท่านั้น)

/// ตัวกติกา (Rule) หนึ่งรายการ
@immutable
class RuleSpec {
  const RuleSpec({
    required this.id,
    required this.name,
    required this.enabled,
    required this.severity,
    required this.condition,
    this.cooldownSeconds = 0,
    this.tags = const <String>[], // เช่น ['diabetes','sleep']
    this.actions = const <act.ActionSpec>[], // ✅ อ้างถึง act.ActionSpec
  });

  final String id;                // unique
  final String name;              // ชื่ออ่านง่าย
  final bool enabled;
  final Severity severity;
  final ConditionNode condition;  // โหนดเงื่อนไข
  final int cooldownSeconds;      // กันเด้งซ้ำถี่ ๆ
  final List<String> tags;        // ใช้จับคู่กับโปรไฟล์/แผน
  final List<act.ActionSpec> actions; // ✅

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'enabled': enabled,
        'severity': severity.name,
        'cooldown_seconds': cooldownSeconds,
        'tags': tags,
        'condition': condition.toJson(),
        'actions': actions.map((a) => a.toJson()).toList(growable: false),
      };

  factory RuleSpec.fromJson(Map<String, dynamic> m) => RuleSpec(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        enabled: (m['enabled'] as bool?) ?? true,
        severity: Severity.values.firstWhere(
          (e) => e.name == (m['severity'] ?? 'info'),
          orElse: () => Severity.info,
        ),
        cooldownSeconds: (m['cooldown_seconds'] as int?) ?? 0,
        tags: (m['tags'] as List? ?? const []).whereType<String>().toList(),
        condition: ConditionNode.fromJson(
            (m['condition'] as Map?)?.cast<String, dynamic>() ?? const {}),
        actions: (m['actions'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => act.ActionSpec.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false),
      );

  /// ประเมินกติกากับ metrics ปัจจุบัน (เช็คอย่างเดียว ไม่ยิง action)
  bool matches(Map<String, num> metrics) {
    if (!enabled) return false;
    return condition.evaluate(metrics);
  }
}

/// --------- ตัวอย่างสำเร็จรูป ----------

/// HR > 120 bpm → แจ้งเตือน (ผู้ป่วยเบาหวานอาจใช้ร่วมกับแท็ก 'diabetes')
RuleSpec exampleHighHrRule() {
  return RuleSpec(
    id: 'rule.hr_high',
    name: 'High heart rate',
    enabled: true,
    severity: Severity.warning,
    cooldownSeconds: 600, // 10 นาที
    tags: const ['general', 'diabetes', 'hr'],
    condition: const ConditionNode.leaf(MetricConditionLeaf(
      metricId: 'heart_rate',
      op: CompareOp.gt,
      threshold: ThresholdSource.constant(120),
    )),
    actions: const [
      act.ActionSpec(
        type: 'notify',
        title: 'High heart rate',
        body: 'Your heart rate is above 120 bpm.',
      ),
      act.ActionSpec(
        type: 'surface_card',
        payload: {
          'feature_id': 'for_you',
          'card_id': 'for_you.hr_watch',
        },
      ),
    ],
  );
}

/// (SpO2 < 92%) OR (Sleep < 5h) → แจ้งเตือน
RuleSpec exampleSpO2OrLowSleepRule() {
  return RuleSpec(
    id: 'rule.spo2_or_sleep',
    name: 'Oxygen low or short sleep',
    enabled: true,
    severity: Severity.warning,
    cooldownSeconds: 3600, // 1 ชั่วโมง
    tags: const ['general'],
    condition: ConditionNode.group(
      op: BoolOp.or,
      children: const [
        ConditionNode.leaf(MetricConditionLeaf(
          metricId: 'oxygen_saturation_pct',
          op: CompareOp.lt,
          threshold: ThresholdSource.constant(92),
        )),
        ConditionNode.leaf(MetricConditionLeaf(
          metricId: 'sleep_sec',
          op: CompareOp.lt,
          threshold: ThresholdSource.constant(5 * 3600), // < 5 ชั่วโมง
        )),
      ],
    ),
    actions: const [
      act.ActionSpec(
        type: 'notify',
        title: 'Health attention',
        body: 'Low SpO₂ or short sleep detected.',
      ),
    ],
  );
}
