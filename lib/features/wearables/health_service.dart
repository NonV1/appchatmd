import 'dart:async';

import 'package:flutter/services.dart';
import 'package:health/health.dart';

/// กลุ่มข้อมูลที่ขอจาก Health Connect (Steps, HR, Sleep, SpO₂, โภชนาการ ฯลฯ)
const _types = <HealthDataType>[
  HealthDataType.STEPS,
  HealthDataType.HEART_RATE,
  HealthDataType.BLOOD_OXYGEN,
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.NUTRITION,
  HealthDataType.BODY_FAT_PERCENTAGE,
  HealthDataType.BLOOD_GLUCOSE,
  HealthDataType.WORKOUT,
];

final List<HealthDataAccess> _perms =
    List<HealthDataAccess>.filled(_types.length, HealthDataAccess.READ);

class HealthDiagnostics {
  final bool isHealthConnectAvailable;
  final HealthConnectSdkStatus? sdkStatus;
  final Map<HealthDataType, bool> permissionStatus;

  const HealthDiagnostics({
    required this.isHealthConnectAvailable,
    required this.sdkStatus,
    required this.permissionStatus,
  });

  bool get hasAllPermissions => permissionStatus.values.every((v) => v);
  bool get requiresUpdate =>
      sdkStatus == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired;
  bool get isInstalled =>
      sdkStatus != null && sdkStatus != HealthConnectSdkStatus.sdkUnavailable;
}

class WearableMetric {
  final String id;
  final String title;
  final String value;
  final String? subtitle;

  const WearableMetric({
    required this.id,
    required this.title,
    required this.value,
    this.subtitle,
  });
}

class WearableSnapshot {
  final List<WearableMetric> metrics;
  const WearableSnapshot({required this.metrics});

  bool get hasMetrics => metrics.isNotEmpty;
}

class HealthService {
  static const MethodChannel _hcChannel =
      MethodChannel('com.example.chatmd_v1/health_connect');

  final Health _health = Health();
  bool _configured = false;

  Timer? _pollTimer;
  final _pollInterval = const Duration(minutes: 10);
  final _snapshotCtrl = StreamController<WearableSnapshot?>.broadcast();
  Stream<WearableSnapshot?> get snapshots => _snapshotCtrl.stream;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool> ensureHealthConnectInstalled() async {
    await _ensureConfigured();
    final available = await _health.isHealthConnectAvailable();
    if (available) return true;
    await _health.installHealthConnect();
    return false;
  }

  Future<bool> isHealthConnectAvailable() async {
    await _ensureConfigured();
    return _health.isHealthConnectAvailable();
  }

  Future<HealthDiagnostics> diagnostics() async {
    await _ensureConfigured();
    final status = await _health.getHealthConnectSdkStatus();
    final available = await _health.isHealthConnectAvailable();
    final Map<HealthDataType, bool> perType = {};
    for (final t in _types) {
      final ok = await _health.hasPermissions([t],
              permissions: const [HealthDataAccess.READ]) ??
          false;
      perType[t] = ok;
    }
    return HealthDiagnostics(
      isHealthConnectAvailable: available,
      sdkStatus: status,
      permissionStatus: perType,
    );
  }

  Future<bool> openHealthConnectApp() async {
    try {
      final ok = await _hcChannel.invokeMethod<bool>('openHealthConnect');
      return ok ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    await _ensureConfigured();
    final available = await _health.isHealthConnectAvailable();
    if (!available) {
      await _health.installHealthConnect();
      return false;
    }
    return await _health.requestAuthorization(_types, permissions: _perms);
  }

  /// ดึงข้อมูลรอบวัน (00:00 ถึงปัจจุบัน) เฉพาะ metric ที่มีจริงเท่านั้น
  Future<WearableSnapshot?> fetchToday() async {
    await _ensureConfigured();

    final has =
        await _health.hasPermissions(_types, permissions: _perms) ?? false;
    if (!has) return null;

    final now = DateTime.now();
    final day0 = DateTime(now.year, now.month, now.day);

    final metrics = <WearableMetric>[];

    final steps = await _stepsMetric(day0, now);
    if (steps != null) metrics.add(steps);

    final hr = await _latestMetric(
      id: 'heart_rate',
      title: 'Heart Rate ล่าสุด',
      type: HealthDataType.HEART_RATE,
      start: day0,
      end: now,
      unit: 'bpm',
    );
    if (hr != null) metrics.add(hr);

    final spo2 = await _latestMetric(
      id: 'spo2',
      title: 'SpO₂ ล่าสุด',
      type: HealthDataType.BLOOD_OXYGEN,
      start: day0,
      end: now,
      unit: '%',
    );
    if (spo2 != null) metrics.add(spo2);

    final sleep = await _sleepMetric(
      start: day0.subtract(const Duration(hours: 24)),
      end: now,
    );
    if (sleep != null) metrics.add(sleep);

    final activeEnergy = await _sumMetric(
      id: 'active_energy',
      title: 'แคลอรีที่เผาผลาญ',
      unit: 'kcal',
      type: HealthDataType.ACTIVE_ENERGY_BURNED,
      start: day0,
      end: now,
    );
    if (activeEnergy != null) metrics.add(activeEnergy);

    final nutrition = await _nutritionMetric(day0, now);
    if (nutrition != null) metrics.add(nutrition);

    final bodyFat = await _latestMetric(
      id: 'body_fat',
      title: 'เปอร์เซ็นต์ไขมัน',
      type: HealthDataType.BODY_FAT_PERCENTAGE,
      start: now.subtract(const Duration(days: 30)),
      end: now,
      unit: '%',
      decimals: 1,
    );
    if (bodyFat != null) metrics.add(bodyFat);

    final glucose = await _latestMetric(
      id: 'blood_glucose',
      title: 'น้ำตาลในเลือด',
      type: HealthDataType.BLOOD_GLUCOSE,
      start: now.subtract(const Duration(days: 7)),
      end: now,
      unit: 'mg/dL',
    );
    if (glucose != null) metrics.add(glucose);

    final workouts = await _workoutMetric(day0, now);
    if (workouts != null) metrics.add(workouts);

    return WearableSnapshot(metrics: metrics);
  }

  Future<WearableMetric?> _stepsMetric(DateTime start, DateTime end) async {
    final total = await _sumNumeric(
      types: const [HealthDataType.STEPS],
      start: start,
      end: end,
    );
    if (total == null) return null;
    final steps = total.round();
    return WearableMetric(
      id: 'steps',
      title: 'Steps วันนี้',
      value: '$steps ก้าว',
    );
  }

  Future<WearableMetric?> _sleepMetric({
    required DateTime start,
    required DateTime end,
  }) async {
    final seconds = await _sumDurationSeconds(
      types: const [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
      ],
      start: start,
      end: end,
    );
    if (seconds <= 0) return null;
    final duration = Duration(seconds: seconds);
    return WearableMetric(
      id: 'sleep',
      title: 'เวลานอน (24 ชม.ล่าสุด)',
      value: _formatDuration(duration),
    );
  }

  Future<WearableMetric?> _latestMetric({
    required String id,
    required String title,
    required HealthDataType type,
    required DateTime start,
    required DateTime end,
    required String unit,
    int decimals = 0,
  }) async {
    final value = await _latestNumeric(
      types: [type],
      start: start,
      end: end,
    );
    if (value == null) return null;
    return WearableMetric(
      id: id,
      title: title,
      value: '${value.toStringAsFixed(decimals)} $unit',
    );
  }

  Future<WearableMetric?> _sumMetric({
    required String id,
    required String title,
    required HealthDataType type,
    required DateTime start,
    required DateTime end,
    required String unit,
    int decimals = 0,
  }) async {
    final value = await _sumNumeric(
      types: [type],
      start: start,
      end: end,
    );
    if (value == null) return null;
    return WearableMetric(
      id: id,
      title: title,
      value: '${value.toStringAsFixed(decimals)} $unit',
    );
  }

  Future<WearableMetric?> _nutritionMetric(
      DateTime start, DateTime end) async {
    final meals = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.NUTRITION],
      startTime: start,
      endTime: end,
    );
    double totalCalories = 0;
    for (final m in meals) {
      final value = m.value;
      if (value is NutritionHealthValue) {
        totalCalories += value.calories ?? 0;
      }
    }
    if (totalCalories <= 0) return null;
    return WearableMetric(
      id: 'nutrition',
      title: 'พลังงานที่รับประทาน',
      value: '${totalCalories.toStringAsFixed(0)} kcal',
      subtitle: 'รวมจาก Health Connect วันนี้',
    );
  }

  Future<WearableMetric?> _workoutMetric(
      DateTime start, DateTime end) async {
    final workouts = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.WORKOUT],
      startTime: start,
      endTime: end,
    );
    if (workouts.isEmpty) return null;

    int count = workouts.length;
    double totalEnergy = 0;
    for (final w in workouts) {
      final value = w.value;
      if (value is WorkoutHealthValue) {
        totalEnergy += (value.totalEnergyBurned ?? 0).toDouble();
      }
    }
    final energyText =
        totalEnergy > 0 ? ' • ${totalEnergy.toStringAsFixed(0)} kcal' : '';
    return WearableMetric(
      id: 'workouts',
      title: 'การออกกำลังกาย',
      value: '$count ครั้ง$energyText',
    );
  }

  Future<double?> _latestNumeric({
    required List<HealthDataType> types,
    required DateTime start,
    required DateTime end,
  }) async {
    final data = await _health.getHealthDataFromTypes(
      types: types,
      startTime: start,
      endTime: end,
    );
    if (data.isEmpty) return null;
    data.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    return _asDouble(data.last.value);
  }

  Future<double?> _sumNumeric({
    required List<HealthDataType> types,
    required DateTime start,
    required DateTime end,
  }) async {
    final data = await _health.getHealthDataFromTypes(
      types: types,
      startTime: start,
      endTime: end,
    );
    double total = 0;
    var found = false;
    for (final d in data) {
      final value = _asDouble(d.value);
      if (value != null) {
        total += value;
        found = true;
      }
    }
    return found ? total : null;
  }

  Future<int> _sumDurationSeconds({
    required List<HealthDataType> types,
    required DateTime start,
    required DateTime end,
  }) async {
    final data = await _health.getHealthDataFromTypes(
      types: types,
      startTime: start,
      endTime: end,
    );
    var total = 0;
    for (final d in data) {
      final sec = d.dateTo.difference(d.dateFrom).inSeconds;
      if (sec > 0) total += sec;
    }
    return total;
  }

  double? _asDouble(dynamic value) {
    if (value is NumericHealthValue) return value.numericValue.toDouble();
    if (value is num) return value.toDouble();
    return null;
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m';
  }

  /// ---------------- Auto polling (ทุกๆ 10 นาทีในขณะเปิดแอป) ----------------

  Future<void> startAutoPolling() async {
    await _emitLatestOnce();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _emitLatestOnce());
  }

  void stopAutoPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _emitLatestOnce() async {
    try {
      final snap = await fetchToday();
      _snapshotCtrl.add(snap);
    } catch (_) {
      _snapshotCtrl.add(null);
    }
  }

  void dispose() {
    stopAutoPolling();
    _snapshotCtrl.close();
  }
}
