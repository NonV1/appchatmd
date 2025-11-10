// lib/core/models/wearable_metrics.dart

/// ---------- Metric IDs มาตรฐาน (string-based, ขยายง่าย) ----------
class MetricIds {
  // เดิม (คงชื่อเพื่อ backward compatibility)
  static const steps = 'steps';
  static const heartRate = 'heart_rate';          // bpm (latest today)
  static const sleepSec = 'sleep_sec';            // วินาที (24h ล่าสุด)
  static const activeEnergyKcal = 'active_energy_kcal'; // kcal (today, activity)

  // เพิ่มตาม permission ที่เปิดไว้
  static const oxygenSaturationPct = 'oxygen_saturation_pct'; // SpO2 %
  static const bodyFatPct = 'body_fat_pct';                   // % body fat
  static const bloodGlucoseMgdl = 'blood_glucose_mgdl';       // mg/dL
  static const nutritionEnergyKcal = 'nutrition_energy_kcal'; // kcal intake (today)
  static const exerciseMinutes = 'exercise_minutes';          // นาทีออกกำลัง (today)
  static const exerciseSessions = 'exercise_sessions';        // จำนวน session (today)

  // เผื่ออนาคต: average/resting/max HR วันนี้
  static const heartRateResting = 'heart_rate_resting';
  static const heartRateMax = 'heart_rate_max';
  static const heartRateAvg = 'heart_rate_avg';
}

/// ---------- เมตาดาต้าแต่ละ metric (ไม่ผูก UI) ----------
class MetricMeta {
  const MetricMeta({
    required this.id,
    required this.label,
    this.unit,
    this.description,
    this.preferInteger = false,
    this.higherIsBetter,
  });

  final String id;
  final String label;
  final String? unit;        // เช่น bpm, %, mg/dL, kcal, min
  final String? description; // ใช้แสดง tooltip/รายละเอียด
  final bool preferInteger;
  final bool? higherIsBetter; // null = ไม่กำหนด
}

/// คลังเมตาดาต้าพื้นฐาน
class MetricCatalog {
  static const Map<String, MetricMeta> all = {
    // เดิม
    MetricIds.steps: MetricMeta(
      id: MetricIds.steps,
      label: 'Steps',
      higherIsBetter: true,
      preferInteger: true,
      description: 'Total steps today',
    ),
    MetricIds.heartRate: MetricMeta(
      id: MetricIds.heartRate,
      label: 'Heart rate',
      unit: 'bpm',
      description: 'Latest heart rate today',
      preferInteger: true,
    ),
    MetricIds.sleepSec: MetricMeta(
      id: MetricIds.sleepSec,
      label: 'Sleep',
      unit: 'sec',
      description: 'Sleep in last 24h',
      preferInteger: true,
      higherIsBetter: true,
    ),
    MetricIds.activeEnergyKcal: MetricMeta(
      id: MetricIds.activeEnergyKcal,
      label: 'Active energy',
      unit: 'kcal',
      description: 'Energy burned from activity today',
    ),

    // เพิ่มตาม permission
    MetricIds.oxygenSaturationPct: MetricMeta(
      id: MetricIds.oxygenSaturationPct,
      label: 'SpO₂',
      unit: '%',
      description: 'Oxygen saturation (latest)',
      preferInteger: true,
      higherIsBetter: true,
    ),
    MetricIds.bodyFatPct: MetricMeta(
      id: MetricIds.bodyFatPct,
      label: 'Body fat',
      unit: '%',
      description: 'Body fat percentage',
    ),
    MetricIds.bloodGlucoseMgdl: MetricMeta(
      id: MetricIds.bloodGlucoseMgdl,
      label: 'Blood glucose',
      unit: 'mg/dL',
      description: 'Latest blood glucose reading',
      preferInteger: true,
    ),
    MetricIds.nutritionEnergyKcal: MetricMeta(
      id: MetricIds.nutritionEnergyKcal,
      label: 'Intake',
      unit: 'kcal',
      description: 'Dietary energy intake today',
      preferInteger: true,
    ),
    MetricIds.exerciseMinutes: MetricMeta(
      id: MetricIds.exerciseMinutes,
      label: 'Exercise',
      unit: 'min',
      description: 'Total exercise minutes today',
      preferInteger: true,
      higherIsBetter: true,
    ),
    MetricIds.exerciseSessions: MetricMeta(
      id: MetricIds.exerciseSessions,
      label: 'Sessions',
      description: 'Exercise sessions today',
      preferInteger: true,
      higherIsBetter: true,
    ),

    // เผื่ออนาคต HR enrich
    MetricIds.heartRateResting: MetricMeta(
      id: MetricIds.heartRateResting,
      label: 'Resting HR',
      unit: 'bpm',
      description: 'Resting heart rate (today)',
      preferInteger: true,
    ),
    MetricIds.heartRateMax: MetricMeta(
      id: MetricIds.heartRateMax,
      label: 'Max HR',
      unit: 'bpm',
      description: 'Maximum HR today',
      preferInteger: true,
    ),
    MetricIds.heartRateAvg: MetricMeta(
      id: MetricIds.heartRateAvg,
      label: 'Avg HR',
      unit: 'bpm',
      description: 'Average HR today',
      preferInteger: true,
    ),
  };

  static MetricMeta? of(String id) => all[id];
}

/// ---------- ค่า metric เดี่ยว พร้อมตัวช่วยฟอร์แมต ----------
class MetricValue {
  const MetricValue({
    required this.id,
    required this.value,
    required this.measuredAt,
  });

  final String id;
  final num value;
  final DateTime measuredAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
        'measured_at': measuredAt.toIso8601String(),
      };

  String formatValue({int fractionDigits = 0}) {
    final meta = MetricCatalog.of(id);
    final useInt = meta?.preferInteger ?? (fractionDigits == 0);
    if (useInt) return value.round().toString();
    return value.toStringAsFixed(fractionDigits);
  }
}

/// ---------- สแน็ปช็อตรวม (อ่านครั้งหนึ่ง) ----------
class WearableMetricsSnapshot {
  WearableMetricsSnapshot({
    required this.metrics,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  /// map: metricId -> ค่าตัวเลข
  final Map<String, num> metrics;
  final DateTime fetchedAt;

  // Helpers เดิม
  int? get steps => _asInt(metrics[MetricIds.steps]);
  double? get heartRate => _asDouble(metrics[MetricIds.heartRate]);
  Duration? get sleep {
    final sec = _asInt(metrics[MetricIds.sleepSec]);
    return (sec == null) ? null : Duration(seconds: sec);
  }
  double? get activeEnergyKcal => _asDouble(metrics[MetricIds.activeEnergyKcal]);

  // Helpers ใหม่ (เลือกใช้ใน “เฉพาะคุณ”/การ์ดเฉพาะโรค)
  double? get spo2Pct => _asDouble(metrics[MetricIds.oxygenSaturationPct]);
  double? get bodyFatPct => _asDouble(metrics[MetricIds.bodyFatPct]);
  double? get bloodGlucoseMgdl => _asDouble(metrics[MetricIds.bloodGlucoseMgdl]);
  int? get nutritionKcal => _asInt(metrics[MetricIds.nutritionEnergyKcal]);
  int? get exerciseMin => _asInt(metrics[MetricIds.exerciseMinutes]);
  int? get exerciseCount => _asInt(metrics[MetricIds.exerciseSessions]);

  // HR enrich (optional)
  double? get hrResting => _asDouble(metrics[MetricIds.heartRateResting]);
  double? get hrMax => _asDouble(metrics[MetricIds.heartRateMax]);
  double? get hrAvg => _asDouble(metrics[MetricIds.heartRateAvg]);

  List<MetricValue> toList() => metrics.entries
      .map((e) => MetricValue(id: e.key, value: e.value, measuredAt: fetchedAt))
      .toList(growable: false);

  Map<String, dynamic> toJson() => {
        'metrics': metrics.map((k, v) => MapEntry(k, v)),
        'fetched_at': fetchedAt.toIso8601String(),
      };

  /// โรงงานสร้างจากค่าพื้นฐาน (ใส่เฉพาะที่มี)
  factory WearableMetricsSnapshot.fromPrimitives({
    // เดิม
    required int steps,
    double? heartRate,
    Duration? sleep,
    double? activeEnergyKcal,
    // ใหม่
    double? spo2Pct,
    double? bodyFatPct,
    double? bloodGlucoseMgdl,
    int? nutritionEnergyKcal,
    int? exerciseMinutes,
    int? exerciseSessions,
    // HR enrich
    double? hrResting,
    double? hrMax,
    double? hrAvg,
    DateTime? fetchedAt,
  }) {
    final m = <String, num>{};
    m[MetricIds.steps] = steps;
    if (heartRate != null) m[MetricIds.heartRate] = heartRate;
    if (sleep != null) m[MetricIds.sleepSec] = sleep.inSeconds;
    if (activeEnergyKcal != null) m[MetricIds.activeEnergyKcal] = activeEnergyKcal;

    // เพิ่ม
    if (spo2Pct != null) m[MetricIds.oxygenSaturationPct] = spo2Pct;
    if (bodyFatPct != null) m[MetricIds.bodyFatPct] = bodyFatPct;
    if (bloodGlucoseMgdl != null) m[MetricIds.bloodGlucoseMgdl] = bloodGlucoseMgdl;
    if (nutritionEnergyKcal != null) {
      m[MetricIds.nutritionEnergyKcal] = nutritionEnergyKcal;
    }
    if (exerciseMinutes != null) m[MetricIds.exerciseMinutes] = exerciseMinutes;
    if (exerciseSessions != null) m[MetricIds.exerciseSessions] = exerciseSessions;

    if (hrResting != null) m[MetricIds.heartRateResting] = hrResting;
    if (hrMax != null) m[MetricIds.heartRateMax] = hrMax;
    if (hrAvg != null) m[MetricIds.heartRateAvg] = hrAvg;

    return WearableMetricsSnapshot(metrics: m, fetchedAt: fetchedAt);
  }

  // ---- helpers ----
  static int? _asInt(num? v) => v?.toInt();
  static double? _asDouble(num? v) => v?.toDouble();
}
