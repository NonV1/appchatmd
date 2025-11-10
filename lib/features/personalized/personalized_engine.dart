// lib/features/personalized/personalized_engine.dart
import 'package:flutter/foundation.dart';

import '../../core/models/user_profile.dart';
import '../../core/models/wearable_metrics.dart';
import '../../core/models/rule.dart';
import '../../core/rules/rule_engine.dart';

/// รายการ “สิ่งที่แนะนำสำหรับคุณ” เพื่อส่งให้การ์ดแสดง
@immutable
class ForYouEntry {
  const ForYouEntry({
    required this.title,
    required this.subtitle,
    required this.icon,       // Material icon codePoint (เก็บเป็น int จะง่ายต่อ serialize)
    required this.routeName,  // เมื่อกดแล้วไปไหน
    this.payload,             // ออปชัน: ข้อมูลเพิ่ม เช่น cardId, featureId
  });

  final String title;
  final String subtitle;
  final int icon;
  final String routeName;
  final Map<String, dynamic>? payload;
}

/// ตัวช่วยสร้าง “รายการคำแนะนำเฉพาะคุณ” จากโปรไฟล์ + metrics + rules
class PersonalizedEngine {
  const PersonalizedEngine();

  /// กรอง rules ด้วยแท็กในโปรไฟล์ (เช่น conditions) + แท็กทั่วไป ('general')
  List<RuleSpec> _filterRulesForProfile(
    List<RuleSpec> all,
    UserProfile profile,
  ) {
    final needTags = <String>{'general', ...profile.conditions};
    return all.where((r) {
      if (!r.enabled) return false;
      // ถ้ากติกาไม่ใส่แท็กเลย ถือว่าเป็น general
      if (r.tags.isEmpty) return true;
      return r.tags.any(needTags.contains);
    }).toList(growable: false);
  }

  /// ใช้ RuleEngine ประเมิน แล้ว map ออกมาเป็น ForYouEntry
  List<ForYouEntry> buildForYou({
    required UserProfile profile,
    required Map<String, num> metrics,
    required List<RuleSpec> rules,
    DateTime? now,
  }) {
    final selected = _filterRulesForProfile(rules, profile);
    if (selected.isEmpty) {
      // ไม่มีอะไรเข้ากับโปรไฟล์ → คืน default แนะนำเบื้องต้น
      return _defaultEntriesFallback(metrics: metrics, profile: profile);
    }

    final engine = RuleEngine();
    final snap = WearableMetricsSnapshot(metrics: metrics);
    final decisions = engine.evaluate(
      selected,
      snap,
      ctx: RuleContext(
        isExercising: false,
        now: now ?? DateTime.now(),
      ),
    );

    // map RuleDecision -> ForYouEntry เฉพาะ action type = surface_card / notify
    final out = <ForYouEntry>[];
    for (final d in decisions) {
      for (final a in d.actions) {
        switch (a.type) {
          case 'surface_card':
            // ใช้ข้อมูล payload เพื่อกำหนดปลายทาง
            final featureId = a.payload?['feature_id']?.toString() ?? 'for_you';
            final cardId = a.payload?['card_id']?.toString() ?? 'for_you.card';
            out.add(ForYouEntry(
              title: d.rule.name,
              subtitle: 'Personalized suggestion',
              icon: 0xf0ed, // Icons.recommend_outlined.codePoint
              routeName: _routeForFeature(featureId),
              payload: {'card_id': cardId, 'feature_id': featureId},
            ));
            break;
          case 'notify':
            // แปลง notify เป็น suggestion ให้เปิดหน้าที่เกี่ยวข้อง
            out.add(ForYouEntry(
              title: a.title ?? d.rule.name,
              subtitle: a.body ?? 'Tap to review',
              icon: 0xe87c, // Icons.notifications_none.codePoint
              routeName: _routeForSeverity(d.rule.severity),
              payload: {'source': 'rule_notify', 'rule_id': d.rule.id},
            ));
            break;
          default:
            // ข้าม type อื่น ๆ (log ฯลฯ) ไม่ต้องขึ้นการ์ด
            break;
        }
      }
    }

    // ถ้าว่างเปล่า ให้มี default แนะนำอย่างน้อย 1–2 รายการ
    return out.isEmpty
        ? _defaultEntriesFallback(metrics: metrics, profile: profile)
        : out;
  }

  /// route จาก feature_id (เชื่อมกับโครง routes ใน project)
  String _routeForFeature(String featureId) {
    switch (featureId) {
      case 'wearable':
        return '/wearables';
      case 'ai':
      case 'ai_chat':
        return '/ai_chat';
      case 'ai_disease':
        return '/ai_disease';
      case 'food':
        return '/food';
      case 'fit':
        return '/fit';
      default:
        return '/'; // กลับหน้า Home
    }
  }

  /// route จากความรุนแรงของเหตุการณ์
  String _routeForSeverity(Severity s) {
    switch (s) {
      case Severity.critical:
      case Severity.warning:
        // พาเข้าหน้า Wearables ก่อน ให้ผู้ใช้เช็คค่า
        return '/wearables';
      case Severity.info:
      default:
        return '/';
    }
  }

  /// ถ้าไม่มี rule ไหนติด → สร้างคำแนะนำพื้นฐานจาก metrics
  List<ForYouEntry> _defaultEntriesFallback({
    required Map<String, num> metrics,
    required UserProfile profile,
  }) {
    final out = <ForYouEntry>[];

    // ถ้า HR มีค่าจริง → เสนอให้ดูรายละเอียดใน wearable
    if (metrics.containsKey(MetricIds.heartRate)) {
      out.add(ForYouEntry(
        title: 'Check today’s heart rate',
        subtitle:
            'Now ${metrics[MetricIds.heartRate]!.toStringAsFixed(0)} bpm',
        icon: 0xe255, // Icons.favorite.codePoint
        routeName: '/wearables',
      ));
    }

    // ถ้าไม่มี HR แต่อยากชวนต่ออุปกรณ์
    if (!metrics.containsKey(MetricIds.heartRate)) {
      out.add(const ForYouEntry(
        title: 'Connect your wearable',
        subtitle: 'Get personalized insights',
        icon: 0xf04ab, // Icons.watch_rounded.codePoint
        routeName: '/wearables',
      ));
    }

    // ปิดท้ายด้วยคำแนะนำทั่วไป
    out.add(const ForYouEntry(
      title: 'Ask our AI anything',
      subtitle: 'Health Q&A • quick tips',
      icon: 0xe0bf, // Icons.chat_bubble_outline.codePoint
      routeName: '/ai_chat',
    ));

    return out;
  }
}
