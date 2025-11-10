// lib/core/data/health_repo.dart
import 'package:health/health.dart';
import '../models/wearable_metrics.dart';

/// อ่านข้อมูลจาก Google Fit / Apple Health / Health Connect
/// - ไม่ mock
/// - แสดงเฉพาะที่อ่านได้จริง (จับด้วย try/catch ราย metric)
class HealthRepo {
  final Health _health = Health();
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    try {
      await _health.configure();
    } catch (_) {}
    _configured = true;
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is NumericHealthValue) return v.numericValue.toDouble();
    final m = RegExp(r'(-?\d+(?:\.\d+)?)').firstMatch(v.toString());
    if (m != null) return double.tryParse(m.group(1)!);
    return null;
  }

  /// ขอสิทธิ์อ่านชนิดข้อมูลที่สนใจทั้งหมดในครั้งเดียว
  Future<bool> _ensureAuthorized() async {
    try {
      await _ensureConfigured();
      const wanted = <HealthDataType>[
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.BODY_FAT_PERCENTAGE,
        HealthDataType.BLOOD_GLUCOSE,
      ];
      // ขอเท่าที่จำเป็น (บางเครื่องขอซ้ำโดยไม่จำเป็นจะ fail)
      final has = await _health.hasPermissions(wanted);
      if (has == true) return true;
      final permissions =
          List<HealthDataAccess>.filled(wanted.length, HealthDataAccess.READ);
      final ok = await _health.requestAuthorization(wanted,
          permissions: permissions);
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  /// ภาพรวมวันนี้ — คืนเฉพาะ metrics ที่อ่านได้จริง
  Future<WearableMetricsSnapshot> fetchToday() async {
    final authed = await _ensureAuthorized();
    if (!authed) return WearableMetricsSnapshot(metrics: {});

    final now = DateTime.now();
    // ดึงข้อมูลย้อนหลัง 24 ชั่วโมง เพื่อให้ครอบคลุมก้าวเดินทั้งหมด
    final startToday = now.subtract(const Duration(hours: 24));
    final metrics = <String, num>{};

    // Steps (รวมวันนี้)
    try {
      // ลองดึงข้อมูลก้าวแบบละเอียด
      final list = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.STEPS],
        startTime: startToday,
        endTime: now,
      );
      double totalSteps = 0;
      print('Found ${list.length} step records');
      for (final p in list) {
        final steps = _asDouble(p.value);
        if (steps != null) {
          totalSteps += steps;
          print('Steps at ${p.dateFrom}: $steps');
        }
      }
      if (totalSteps > 0) metrics[MetricIds.steps] = totalSteps;
    } catch (_) {}

    // Heart rate (ล่าสุดวันนี้)
    try {
      final list = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: startToday,
        endTime: now,
      );
      if (list.isNotEmpty) {
        final v = _asDouble(list.last.value);
        if (v != null) metrics[MetricIds.heartRate] = v;
      }
    } catch (_) {}

    // Sleep (รวม 24 ชม.หลังสุด)
    try {
      final list = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.SLEEP_ASLEEP],
        startTime: now.subtract(const Duration(hours: 24)),
        endTime: now,
      );
      double totalSec = 0;
      for (final p in list) {
        final sec = p.dateTo.difference(p.dateFrom).inSeconds.toDouble();
        if (sec > 0) totalSec += sec;
      }
      if (totalSec > 0) metrics[MetricIds.sleepSec] = totalSec;
    } catch (_) {}

    // Active energy (kcal รวมวันนี้)
    try {
      final list = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startToday,
        endTime: now,
      );
      double sum = 0;
      for (final p in list) {
        final v = _asDouble(p.value);
        if (v != null) sum += v;
      }
      if (sum > 0) metrics[MetricIds.activeEnergyKcal] = sum;
    } catch (_) {}

    // SpO₂ (ล่าสุดวันนี้)
    try {
      final list = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.BLOOD_OXYGEN],
        startTime: startToday,
        endTime: now,
      );
      if (list.isNotEmpty) {
        final v = _asDouble(list.last.value);
        if (v != null) metrics[MetricIds.oxygenSaturationPct] = v;
      }
    } catch (_) {}

    // Body fat (ล่าสุด 7 วัน)
    try {
      final list = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.BODY_FAT_PERCENTAGE],
        startTime: now.subtract(const Duration(days: 7)),
        endTime: now,
      );
      if (list.isNotEmpty) {
        final v = _asDouble(list.last.value);
        if (v != null) metrics[MetricIds.bodyFatPct] = v;
      }
    } catch (_) {}

    // Blood glucose (ล่าสุดวันนี้)
    try {
      final list = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.BLOOD_GLUCOSE],
        startTime: startToday,
        endTime: now,
      );
      if (list.isNotEmpty) {
        final v = _asDouble(list.last.value);
        if (v != null) metrics[MetricIds.bloodGlucoseMgdl] = v;
      }
    } catch (_) {}

    return WearableMetricsSnapshot(metrics: metrics);
  }

  // ================== Day-based helpers (for history up to 30 days) ==================

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _dayEnd(DateTime d) => DateTime(d.year, d.month, d.day + 1);

  Future<Map<String, num>> fetchDayTotals(DateTime day) async {
    if (!await _ensureAuthorized()) return const {};
    final start = _dayStart(day);
    final end = _dayEnd(day);
    final out = <String, num>{};
    // Steps
    try {
      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.STEPS],
        startTime: start,
        endTime: end,
      );
      double sum = 0;
      for (final p in raw) {
        final v = _asDouble(p.value);
        if (v != null) sum += v;
      }
      if (sum > 0) out[MetricIds.steps] = sum;
    } catch (_) {}

    // Active energy
    try {
      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: end,
      );
      double sum = 0;
      for (final p in raw) {
        final v = _asDouble(p.value);
        if (v != null) sum += v;
      }
      if (sum > 0) out[MetricIds.activeEnergyKcal] = sum;
    } catch (_) {}

    // Heart rate (avg of day)
    try {
      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
      double acc = 0;
      int n = 0;
      for (final p in raw) {
        final v = _asDouble(p.value);
        if (v != null) {acc += v; n++;}
      }
      if (n > 0) out[MetricIds.heartRate] = acc / n;
    } catch (_) {}

    // Sleep duration inside day
    try {
      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.SLEEP_ASLEEP],
        startTime: start,
        endTime: end,
      );
      double sec = 0;
      for (final p in raw) {
        final from = p.dateFrom.isBefore(start) ? start : p.dateFrom;
        final to = p.dateTo.isAfter(end) ? end : p.dateTo;
        final s = to.difference(from).inSeconds;
        if (s > 0) sec += s;
      }
      if (sec > 0) out[MetricIds.sleepSec] = sec;
    } catch (_) {}

    return out;
  }

  Future<List<double>> _bucketByHour(List<dynamic> raw, DateTime start) async {
    final buckets = List<double>.filled(24, 0);
    for (final p in raw) {
      final v = _asDouble(p.value);
      if (v == null) continue;
      final hour = p.dateFrom.hour.clamp(0, 23);
      buckets[hour] += v;
    }
    return buckets;
  }

  Future<List<double>> fetchStepsByHour(DateTime day) async {
    if (!await _ensureAuthorized()) return const [];
    final start = _dayStart(day);
    final end = _dayEnd(day);
    try {
      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.STEPS],
        startTime: start,
        endTime: end,
      );
      return _bucketByHour(raw, start);
    } catch (_) {
      return const [];
    }
  }

  Future<List<double>> fetchEnergyByHour(DateTime day) async {
    if (!await _ensureAuthorized()) return const [];
    final start = _dayStart(day);
    final end = _dayEnd(day);
    try {
      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: end,
      );
      return _bucketByHour(raw, start);
    } catch (_) {
      return const [];
    }
  }

  Future<List<double>> fetchHrAvgByHour(DateTime day) async {
    if (!await _ensureAuthorized()) return const [];
    final start = _dayStart(day);
    final end = _dayEnd(day);
    try {
      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
      final buckets = List<List<double>>.generate(24, (_) => []);
      for (final p in raw) {
        final v = _asDouble(p.value);
        if (v == null) continue;
        final hour = p.dateFrom.hour.clamp(0, 23);
        buckets[hour].add(v);
      }
      return buckets
          .map((l) => l.isEmpty ? 0.0 : l.reduce((a, b) => a + b) / l.length)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ================== Series สำหรับกราฟ (ค่าจริง) ==================

  Future<List<double>> fetchHeartRateSeries({
    Duration lookback = const Duration(hours: 3),
    int buckets = 24,
  }) async {
    if (!await _ensureAuthorized()) return const [];
    final now = DateTime.now();
    final from = now.subtract(lookback);
    try {
      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: from,
        endTime: now,
      );
      if (raw.isEmpty) return const [];
      final spanMs = lookback.inMilliseconds / buckets;
      final bins = List<List<double>>.generate(buckets, (_) => []);
      for (final p in raw) {
        final idx = (((p.dateFrom.millisecondsSinceEpoch -
                        from.millisecondsSinceEpoch) /
                    spanMs))
            .floor()
            .clamp(0, buckets - 1);
        final v = _asDouble(p.value);
        if (v != null) bins[idx].add(v);
      }
      return bins
          .map((l) => l.isEmpty ? 0.0 : l.reduce((a, b) => a + b) / l.length)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<double>> fetchStepsSeries({
    Duration lookback = const Duration(hours: 12),
    int buckets = 12,
  }) async {
    if (!await _ensureAuthorized()) return const [];
    final now = DateTime.now();
    final from = now.subtract(lookback);
    try {
      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.STEPS],
        startTime: from,
        endTime: now,
      );
      if (raw.isEmpty) return const [];
      final spanMs = lookback.inMilliseconds / buckets;
      final bins = List<double>.filled(buckets, 0);
      for (final p in raw) {
        final idx = (((p.dateFrom.millisecondsSinceEpoch -
                        from.millisecondsSinceEpoch) /
                    spanMs))
            .floor()
            .clamp(0, buckets - 1);
        final v = _asDouble(p.value);
        if (v != null) bins[idx] += v;
      }
      return bins;
    } catch (_) {
      return const [];
    }
  }

  Future<List<double>> fetchEnergySeries({
    Duration lookback = const Duration(hours: 12),
    int buckets = 12,
  }) async {
    if (!await _ensureAuthorized()) return const [];
    final now = DateTime.now();
    final from = now.subtract(lookback);
    try {
      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: from,
        endTime: now,
      );
      if (raw.isEmpty) return const [];
      final spanMs = lookback.inMilliseconds / buckets;
      final bins = List<double>.filled(buckets, 0);
      for (final p in raw) {
        final idx = (((p.dateFrom.millisecondsSinceEpoch -
                        from.millisecondsSinceEpoch) /
                    spanMs))
            .floor()
            .clamp(0, buckets - 1);
        final v = _asDouble(p.value);
        if (v != null) bins[idx] += v;
      }
      return bins;
    } catch (_) {
      return const [];
    }
  }
}
