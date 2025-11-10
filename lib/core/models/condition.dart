// lib/core/models/condition.dart
import 'package:flutter/foundation.dart';

/// ตัวดำเนินการเปรียบเทียบ
enum CompareOp { gt, gte, lt, lte, eq, ne }

/// ตัวดำเนินการตรรกะ
enum BoolOp { and, or }

/// แหล่งค่า threshold (ตอนนี้รองรับค่าคงที่ไว้ก่อน)
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
    // อนาคต: รองรับ profile/remote
    return ThresholdSource.constant((m['value'] ?? 0) as num);
  }
}

/// ใบไม้: เทียบ metric ตัวเดียวกับ threshold (เช่น heart_rate > 130)
@immutable
class MetricConditionLeaf {
  const MetricConditionLeaf({
    required this.metricId,
    required this.op,
    required this.threshold,
  });

  final String metricId;         // อ้างอิง MetricIds.* ใน wearable_metrics.dart
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

  /// คืน true ก็ต่อเมื่อมี metric นี้ และผ่านเงื่อนไข
  bool evaluate(Map<String, num> metrics) {
    final v = metrics[metricId];
    if (v == null) return false; // ❗ ไม่มีค่าก็ถือว่า "ไม่เข้าเงื่อนไข" → ไม่แจ้งเตือน
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

/// โหนดรวม: AND/OR ของลูกหลายตัว หรือเป็นใบไม้ก็ได้ (เหมือนเดิมเพื่อไม่ให้พังโค้ดเก่า)
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

  /// ---------- Helpers สำหรับสร้างอย่างสั้น ----------
  factory ConditionNode.metric(
    String metricId, {
    required CompareOp op,
    required num threshold,
  }) =>
      ConditionNode.leaf(MetricConditionLeaf(
        metricId: metricId,
        op: op,
        threshold: ThresholdSource.constant(threshold),
      ));

  factory ConditionNode.and(List<ConditionNode> nodes) =>
      ConditionNode.group(op: BoolOp.and, children: nodes);

  factory ConditionNode.or(List<ConditionNode> nodes) =>
      ConditionNode.group(op: BoolOp.or, children: nodes);

  /// ---------- JSON ----------
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

  /// ประเมินเงื่อนไขกับ metrics ปัจจุบัน
  bool evaluate(Map<String, num> metrics) {
    if (leaf != null) return leaf!.evaluate(metrics);
    if (children.isEmpty) return false;
    if (op == BoolOp.and) {
      for (final c in children) {
        if (!c.evaluate(metrics)) return false;
      }
      return true;
    } else {
      for (final c in children) {
        if (c.evaluate(metrics)) return true;
      }
      return false;
    }
  }
}
