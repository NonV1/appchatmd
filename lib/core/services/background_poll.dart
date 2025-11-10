// lib/core/services/background_poll.dart
//
// เบา-ไม่ผูกกับคลาสอื่น: ทุกอย่างฉีดเข้ามาผ่าน configure()
// - Foreground polling ด้วย Timer
// - Android background polling ด้วย Workmanager (>= 15 นาที)
// - เช็คเน็ตด้วย connectivity_plus
//
// ติดตั้งครั้งเดียว:
//   flutter pub add workmanager connectivity_plus

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';

/// ============ Public types (ไม่ผูกกับโมดูลอื่น) ============

/// metrics วันนี้ในรูป Map<metricId, value>
typedef MetricMap = Map<String, num>;

/// ดึง metrics (เช่นจาก HealthRepo) — คุณจะฉีดเข้ามาเองใน main.dart
typedef MetricsFetcher = Future<MetricMap> Function();

/// ระดับความรุนแรง (ตรงไป-ตรงมา ไม่ชนกับ enum อื่นของโปรเจ็กต์)
enum BgSeverity { info, warning, critical }

/// โครงแจ้งเตือนอย่างง่ายจาก Rule Engine
class BgNotification {
  BgNotification({
    required this.id,
    this.title,
    this.body,
    DateTime? createdAt,
    this.severity = BgSeverity.info,
    this.payload,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String? title;
  final String? body;
  final DateTime createdAt;
  final BgSeverity severity;
  final Map<String, dynamic>? payload;
}

/// ผลลัพธ์จาก Rule Evaluator
class BgDecision {
  BgDecision({
    this.notifications = const <BgNotification>[],
    this.actions = const <Map<String, dynamic>>[],
  });

  final List<BgNotification> notifications;
  final List<Map<String, dynamic>> actions;
}

/// ประเมินกติกา (เช่น RuleEngine) — คุณจะฉีดเข้ามาเอง
typedef RuleEvaluator = Future<BgDecision> Function(
  MetricMap metrics,
  DateTime now,
  String reason,
);

/// ยิงผลลัพธ์แจ้งเตือน (เช่น เก็บ Inbox + แสดงแบนเนอร์/OS notif)
typedef NotificationSink = FutureOr<void> Function(
  List<BgNotification> list,
);

/// ============ BackgroundPoll (singleton) ============

class BackgroundPoll {
  BackgroundPoll._();
  static final BackgroundPoll I = BackgroundPoll._();

  // callbacks ที่ฉีดเข้ามา
  late MetricsFetcher _fetcher;
  late RuleEvaluator _evaluator;
  NotificationSink? _onNotifications;

  bool _configured = false;

  // foreground timer
  Timer? _fgTimer;
  bool _enabled = false;
  int _fgIntervalMin = 10;

  // ชื่อ task workmanager
  static const _kBgTaskName = 'chatmd.health.poll';
  static const _kAndroidMinIntervalMin = 15;

  /// เรียกครั้งเดียวตอน boot: ฉีด dependency ทั้งหมด
  void configure({
    required MetricsFetcher fetcher,
    required RuleEvaluator evaluator,
    NotificationSink? onNotifications,
  }) {
    _fetcher = fetcher;
    _evaluator = evaluator;
    _onNotifications = onNotifications;
    _configured = true;
  }

  /// ต้องเรียกใน main() ก่อน runApp()
  Future<void> init() async {
    if (Platform.isAndroid) {
      await Workmanager().initialize(
        _callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
    }
  }

  /// เปิด/ปิด + ตั้งช่วง foreground และ background (Android)
  Future<void> setEnabled(bool enabled, {int intervalMin = 10}) async {
    assert(_configured, 'BackgroundPoll.configure() must be called first.');
    _enabled = enabled;
    _fgIntervalMin = intervalMin.clamp(5, 360);

    _fgTimer?.cancel();
    if (_enabled) {
      // ยิงรอบแรกทันทีแบบเบา ๆ
      scheduleMicrotask(() => _pollOnce(reason: 'fg_boot'));
      _fgTimer = Timer.periodic(
        Duration(minutes: _fgIntervalMin),
        (_) => _pollOnce(reason: 'fg_timer'),
      );
    }

    if (Platform.isAndroid) {
      await Workmanager().cancelByUniqueName(_kBgTaskName);
      if (_enabled) {
        final effective = intervalMin < _kAndroidMinIntervalMin
            ? _kAndroidMinIntervalMin
            : intervalMin;

        await Workmanager().registerPeriodicTask(
          _kBgTaskName, // unique
          _kBgTaskName, // task name
          frequency: Duration(minutes: effective),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresCharging: false,
            requiresBatteryNotLow: false,
          ),
        );
      }
    }
  }

  /// ให้ผู้ใช้กดรีเฟรชเอง
  Future<void> triggerOnce({String reason = 'manual'}) => _pollOnce(reason: reason);

  /// core flow (ใช้ร่วมกัน fg/bg)
  Future<void> _pollOnce({required String reason}) async {
    // เช็คเน็ตก่อน (กัน err เงียบ ๆ)
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) return;

    // ดึง metrics (จาก callback)
    MetricMap metrics;
    try {
      metrics = await _fetcher();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[BackgroundPoll] fetcher error: $e');
      }
      return;
    }

    // ประเมินกติกา
    BgDecision decision;
    try {
      decision = await _evaluator(metrics, DateTime.now(), reason);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[BackgroundPoll] evaluator error: $e');
      }
      return;
    }

    if (decision.notifications.isEmpty) return;

    // ส่งต่อผลแจ้งเตือนให้ผู้ที่ฉีด callback มา (เช่นเก็บ Inbox + แสดง banner)
    try {
      await _onNotifications?.call(decision.notifications);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[BackgroundPoll] onNotifications error: $e');
      }
    }
  }
}

/// ------ Workmanager callback (Android ต้องเป็น top-level) ------
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // หมายเหตุ: isolate นี้ไม่มี access ถึง callback ที่คุณฉีดไว้
      // ทางแก้ง่าย ๆ: ให้ foreground เป็นตัวหลัก (ลื่นและแม่นยำกว่า)
      // ถ้าจำเป็นต้องรันจริง ๆ เบื้องหลัง: เปลี่ยนมาใช้ service/DB ที่เรียกได้จาก isolate นี้
      // สำหรับตอนนี้ คืน true ไปก่อน
      return Future.value(true);
    } catch (_) {
      return Future.value(false);
    }
  });
}
