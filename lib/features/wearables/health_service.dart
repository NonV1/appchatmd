// lib/features/wearables/health_service.dart
import 'dart:io' show Platform;
import 'package:health/health.dart';

import '../../core/models/wearable_metrics.dart';

/// บริการอ่านค่าจาก Health Connect (Android) / HealthKit (iOS)
class HealthService {
  HealthService();

  final Health _health = Health();
  bool _configured = false;

  /// เรียกครั้งแรกก่อนใช้งาน
  Future<void> configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Health Connect มีอยู่ไหม (Android เท่านั้น)
  Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _health.isHealthConnectAvailable();
    } catch (_) {
      return false;
    }
  }

  /// ขอสิทธิ์เท่าที่ต้องใช้/เท่าที่เครื่องรองรับ
  Future<bool> ensurePermissions() async {
    await configure();

    // ชุดชนิดข้อมูลที่ “อยากอ่าน”
    final wanted = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      // HealthDataType.NUTRITION, // ปิดไว้ก่อนเพื่อเลี่ยงปัญหา field แตกต่าง
    ];

    // คัดเฉพาะที่อุปกรณ์รองรับ
    final supported = <HealthDataType>[];
    for (final t in wanted) {
      try {
        final ok = _health.isDataTypeAvailable(t);
        if (ok) supported.add(t);
      } catch (_) {
        // บางรุ่นจะโยน exception ให้ข้ามไป
      }
    }
    if (supported.isEmpty) return false;

    // สิทธิ์อ่าน (READ) ให้ครบตามจำนวน type
    final permissions =
        List<HealthDataAccess>.filled(supported.length, HealthDataAccess.READ);

    // ถ้ามีอยู่แล้วก็ผ่านเลย
    final has = await _health.hasPermissions(supported);
    if (has == true) return true;

    // ขอสิทธิ์
    final ok = await _health.requestAuthorization(
      supported,
      permissions: permissions,
    );
    return ok;
  }

  /// ดึงค่าตั้งแต่เที่ยงคืนวันนี้ถึงตอนนี้
  /// คืน: Map<metricId, value> — เฉพาะ key ที่อ่านได้จริงเท่านั้น
  Future<Map<String, num>> fetchToday() async {
    final out = <String, num>{};

    await configure();
    final granted = await ensurePermissions();
    if (!granted) return out; // ไม่มี permission ใด ๆ ก็คืนว่าง

    final now = DateTime.now();
    final today0 = DateTime(now.year, now.month, now.day);

    // 1) Steps
    try {
      final steps = await _health.getTotalStepsInInterval(today0, now);
      if (steps != null) {
        out[MetricIds.steps] = steps;
      }
    } catch (_) {}

    // 2) Heart rate (เอา “ค่าล่าสุด”)
    try {
      final hrs = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: today0,
        endTime: now,
      );
      if (hrs.isNotEmpty) {
        final v = hrs.last.value;
        if (v is NumericHealthValue) {
          out[MetricIds.heartRate] = v.numericValue.toDouble();
        }
      }
    } catch (_) {}

    // 3) Sleep (รวมเวลาหลับทั้งหมดเป็นวินาที)
    try {
      final sleeps = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.SLEEP_ASLEEP],
        startTime: today0,
        endTime: now,
      );
      if (sleeps.isNotEmpty) {
        int totalSec = 0;
        for (final s in sleeps) {
          final sec = s.dateTo.difference(s.dateFrom).inSeconds;
          if (sec > 0) totalSec += sec;
        }
        if (totalSec > 0) {
          out[MetricIds.sleepSec] = totalSec;
        }
      }
    } catch (_) {}

    // 4) Oxygen saturation (เอาค่าล่าสุด %)
    try {
      final oxy = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.BLOOD_OXYGEN],
        startTime: today0,
        endTime: now,
      );
      if (oxy.isNotEmpty) {
        final v = oxy.last.value;
        if (v is NumericHealthValue) {
          out[MetricIds.oxygenSaturationPct] = v.numericValue.toDouble();
        }
      }
    } catch (_) {}

    // 5) Active energy (รวม kcal วันนี้)
    try {
      final kcals = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: today0,
        endTime: now,
      );
      if (kcals.isNotEmpty) {
        num sum = 0;
        for (final e in kcals) {
          final v = e.value;
          if (v is NumericHealthValue) {
            sum += v.numericValue;
          }
        }
        if (sum > 0) {
          out[MetricIds.activeEnergyKcal] = sum.toDouble();
        }
      }
    } catch (_) {}

    // หมายเหตุ: Nutrition (พลังงานจากอาหาร) ยังไม่นิ่งในหลายรุ่น จึงยังไม่อ่านที่นี่

    return out;
  }
}
