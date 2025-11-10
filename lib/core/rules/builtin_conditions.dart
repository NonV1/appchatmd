// lib/core/rules/builtin_conditions.dart
import '../models/condition.dart';
import '../models/wearable_metrics.dart';

/// ---------- ช่วยรวมเงื่อนไขสั้น ๆ ----------
ConditionNode andAll(List<ConditionNode> nodes) => ConditionNode.and(nodes);
ConditionNode orAny(List<ConditionNode> nodes) => ConditionNode.or(nodes);

/// ---------- เงื่อนไขวัดจากตัวชี้วัดสวมใส่ (Wearables) ----------
/// หมายเหตุ:
/// - ถ้า metric ไหน "ไม่มีในเครื่อง" evaluate() จะให้ false อยู่แล้ว (ไม่เด้งเตือน)
/// - ถ้าต้อง “บังคับว่าต้องมีค่า” ให้ใช้ metricAvailable(...) ร่วมด้วย

/// HR > bpm
ConditionNode hrAbove(num bpm) => ConditionNode.metric(
      MetricIds.heartRate, // << แก้ชื่อให้ตรงกับ wearable_metrics.dart
      op: CompareOp.gt,
      threshold: bpm,
    );

/// HR < bpm
ConditionNode hrBelow(num bpm) => ConditionNode.metric(
      MetricIds.heartRate,
      op: CompareOp.lt,
      threshold: bpm,
    );

/// SpO2 < percent
ConditionNode spo2Below(num percent) => ConditionNode.metric(
      MetricIds.oxygenSaturationPct,
      op: CompareOp.lt,
      threshold: percent,
    );

/// ก้าวเดินวันนี้ > steps
ConditionNode stepsAbove(int steps) => ConditionNode.metric(
      MetricIds.steps,
      op: CompareOp.gt,
      threshold: steps,
    );

/// ชั่วโมงนอน (วัดเป็นวินาทีใน metrics) < hours
ConditionNode sleepBelowHours(num hours) => ConditionNode.metric(
      MetricIds.sleepSec,
      op: CompareOp.lt,
      threshold: (hours * 3600).toInt(),
    );

/// พลังงานที่เผาผลาญแอคทีฟ > kcal
ConditionNode activeKcalAbove(int kcal) => ConditionNode.metric(
      MetricIds.activeEnergyKcal,
      op: CompareOp.gt,
      threshold: kcal,
    );

/// น้ำตาลในเลือด (mg/dL) > value
ConditionNode glucoseAbove(num mgdl) => ConditionNode.metric(
      MetricIds.bloodGlucoseMgdl,
      op: CompareOp.gt,
      threshold: mgdl,
    );

/// ไขมันในร่างกาย (%) > value
ConditionNode bodyFatPctAbove(num pct) => ConditionNode.metric(
      MetricIds.bodyFatPct,
      op: CompareOp.gt,
      threshold: pct,
    );

/// โภชนาการพลังงานวันนี้ (kcal ที่กิน) > kcal
ConditionNode nutritionCaloriesAbove(int kcal) => ConditionNode.metric(
      MetricIds.nutritionEnergyKcal,
      op: CompareOp.gt,
      threshold: kcal,
    );

/// ---------- ความพร้อมของข้อมูล / การมีอยู่ของ metric ----------
String _presentFlag(String metricId) => 'present_$metricId';

/// มี metric นี้ (present == 1)
ConditionNode metricAvailable(String metricId) => ConditionNode.metric(
      _presentFlag(metricId),
      op: CompareOp.gte,
      threshold: 1,
    );

/// ไม่มี metric นี้ (present == 0)
ConditionNode metricUnavailable(String metricId) => ConditionNode.metric(
      _presentFlag(metricId),
      op: CompareOp.eq,
      threshold: 0,
    );

/// ---------- ตัวอย่างสำเร็จรูป ----------

/// ผู้ป่วยเบาหวาน: HR > 130 (และต้องมี HR จริง)
ConditionNode diabetesHighHrBasic() => andAll([
      metricAvailable(MetricIds.heartRate),
      hrAbove(130),
    ]);

/// ความเสี่ยง: SpO2 < 92% OR นอนน้อยกว่า 5 ชั่วโมง (ต้องมีอย่างน้อยหนึ่งค่า)
ConditionNode oxygenLowOrShortSleep() => orAny([
      andAll([
        metricAvailable(MetricIds.oxygenSaturationPct),
        spo2Below(92),
      ]),
      andAll([
        metricAvailable(MetricIds.sleepSec),
        sleepBelowHours(5),
      ]),
    ]);

/// สมมุติบริบท Active แบบง่าย ๆ : ก้าว > 0 และ HR >= 110
ConditionNode activeHeuristic() => andAll([
      andAll([
        metricAvailable(MetricIds.steps),
        stepsAbove(0),
      ]),
      andAll([
        metricAvailable(MetricIds.heartRate),
        hrAbove(110),
      ]),
    ]);
