// lib/core/rules/rule_engine.dart

import 'package:flutter/foundation.dart';

// ✅ เปลี่ยน prefix เพื่อลดชนชื่อกับฟิลด์ actions
import '../models/action.dart' as act;
import '../models/rule.dart' as rules;
import '../models/wearable_metrics.dart';

/// บริบทการประเมินกฎ
@immutable
class RuleContext {
  final bool isExercising; // โหมดออกกำลัง (จาก service หรือปุ่ม toggle)
  final DateTime now;

  RuleContext({
    required this.isExercising,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  factory RuleContext.current({bool isExercising = false}) =>
      RuleContext(isExercising: isExercising, now: DateTime.now());
}

/// ฟังก์ชันตรวจว่าจะ suppress กติกาหรือไม่ (เช่น ระหว่างออกกำลังกาย)
typedef SuppressFn = bool Function(
  rules.RuleSpec rule,
  WearableMetricsSnapshot snap,
  RuleContext ctx,
);

/// ผลการตัดสินของ 1 กฎ
@immutable
class RuleDecision {
  final rules.RuleSpec rule;
  final bool matched;                 // เงื่อนไขผ่าน
  final bool suppressed;              // ถูกกดพัก
  final List<act.ActionSpec> actions; // ✅ ใช้ prefix act แทน

  const RuleDecision({
    required this.rule,
    required this.matched,
    required this.suppressed,
    required this.actions,
  });

  @override
  String toString() =>
      'RuleDecision(rule=${rule.id}, matched=$matched, suppressed=$suppressed, actions=${actions.length})';
}

class RuleEngine {
  RuleEngine({
    this.defaultCooldownSec = 900, // 15 นาที
    SuppressFn? suppressor,
  }) : _suppressor = suppressor ?? _defaultSuppressor;

  final int defaultCooldownSec;
  final SuppressFn _suppressor;

  /// จำเวลา “ยิงครั้งล่าสุด” ต่อกฎ (in-memory)
  final Map<String, DateTime> _lastFiredAt = {};

  void resetCooldown() => _lastFiredAt.clear();

  bool _coolingDown(rules.RuleSpec r, DateTime now) {
    final last = _lastFiredAt[r.id];
    if (last == null) return false;
    final cd = Duration(
      seconds: r.cooldownSeconds > 0 ? r.cooldownSeconds : defaultCooldownSec,
    );
    return now.difference(last) < cd;
  }

  /// ประเมินกฎทั้งหมด
  List<RuleDecision> evaluate(
    List<rules.RuleSpec> allRules,
    WearableMetricsSnapshot snap, {
    RuleContext? ctx,
  }) {
    final context = ctx ?? RuleContext.current();
    final out = <RuleDecision>[];

    for (final rule in allRules) {
      if (!rule.enabled) {
        out.add(RuleDecision(
          rule: rule,
          matched: false,
          suppressed: false,
          actions: const [],
        ));
        continue;
      }

      final matched = rule.condition.evaluate(snap.metrics);
      if (!matched) {
        out.add(RuleDecision(
          rule: rule,
          matched: false,
          suppressed: false,
          actions: const [],
        ));
        continue;
      }

      // คูลดาวน์
      if (_coolingDown(rule, context.now)) {
        out.add(RuleDecision(
          rule: rule,
          matched: true,
          suppressed: true, // treat as suppressed-by-cooldown
          actions: const [],
        ));
        continue;
      }

      // กดพักตามบริบท (เช่น โหมดออกกำลัง)
      final suppressed = _suppressor(rule, snap, context);
      if (suppressed) {
        out.add(RuleDecision(
          rule: rule,
          matched: true,
          suppressed: true,
          actions: const [],
        ));
        continue;
      }

      // ผ่านทุกด่าน → ยิง actions และเริ่มคูลดาวน์
      _lastFiredAt[rule.id] = context.now;

      out.add(RuleDecision(
        rule: rule,
        matched: true,
        suppressed: false,
        actions: rule.actions, // ชนิด = List<act.ActionSpec>
      ));
    }

    return out;
  }
}

/// suppressor เริ่มต้น:
/// - ถ้า rule.tags มีทั้ง 'diabetes' และ 'hr' และตอนนี้กำลังออกกำลัง → กดพัก
bool _defaultSuppressor(
  rules.RuleSpec rule,
  WearableMetricsSnapshot snap,
  RuleContext ctx,
) {
  if (ctx.isExercising &&
      rule.tags.contains('diabetes') &&
      rule.tags.contains('hr')) {
    return true;
  }
  return false;
}
