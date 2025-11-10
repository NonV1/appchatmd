// lib/core/alerts/notifier.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/notification_item.dart';
import '../models/action.dart';

/// เปิดเส้นทางภายในแอป (ให้เลเยอร์ UI เซ็ตเข้ามา)
typedef RouteOpener = Future<void> Function(
  String route,
  Map<String, dynamic>? args,
);

/// ดันการ์ดขึ้นในโซนฟีเจอร์ (เช่น "เฉพาะคุณ") — ให้เลเยอร์ UI เซ็ตเข้ามา
typedef SurfaceCardPusher = void Function(
  String featureId,
  String cardId,
  Map<String, dynamic>? extra,
);

/// ศูนย์รวมแจ้งเตือนภายในแอป (in-app inbox)
class InAppNotifier with ChangeNotifier {
  InAppNotifier();

  final List<NotificationItem> _items = <NotificationItem>[];
  final _newController = StreamController<NotificationItem>.broadcast();

  /// อ่านลิสต์ปัจจุบัน (read-only)
  List<NotificationItem> get items => List.unmodifiable(_items);

  /// สตรีมแจ้งเตือนใหม่ (ใช้โชว์แบนเนอร์/สแน็คบาร์แบบ realtime)
  Stream<NotificationItem> get onNew => _newController.stream;

  /// เพิ่มแจ้งเตือนใหม่
  void add(NotificationItem item, {bool notifyImmed = true}) {
    _items.insert(0, item); // ใหม่สุดขึ้นบน
    _newController.add(item);
    if (notifyImmed) notifyListeners();
  }

  /// ทำเครื่องหมายว่าอ่านแล้ว
  void markRead(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i != -1 && !_items[i].isRead) {
      _items[i] = _items[i].markRead();
      notifyListeners();
    }
  }

  /// ลบเฉพาะรายการที่หมดอายุ/อ่านแล้ว (ถ้าต้องการ)
  void prune({bool removeExpired = true, bool removeRead = false}) {
    _items.removeWhere((e) {
      if (removeExpired && e.isExpired) return true;
      if (removeRead && e.isRead) return true;
      return false;
    });
    notifyListeners();
  }

  /// ล้างทั้งหมด
  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// แปลง ActionSpec(type=notify) → NotificationItem
  NotificationItem fromNotifyAction(
    ActionSpec a, {
    String Function()? idGen,
    NotificationLevel defaultLevel = NotificationLevel.info,
    String? ruleId,
    String? featureId,
    String origin = 'engine',
    Duration? ttl, // เช่น Duration(hours: 6)
  }) {
    final now = DateTime.now();
    final payload = a.payload ?? const {};
    final levelStr = (payload['level'] ?? '').toString();
    final level = () {
      switch (levelStr) {
        case 'warning':
          return NotificationLevel.warning;
        case 'critical':
          return NotificationLevel.critical;
        default:
          return defaultLevel;
      }
    }();

    return NotificationItem(
      id: idGen?.call() ?? now.microsecondsSinceEpoch.toString(),
      title: a.title ?? 'Notification',
      body: a.body,
      level: level,
      createdAt: now,
      expiresAt: ttl != null ? now.add(ttl) : null,
      sticky: (payload['sticky'] as bool?) ?? false,
      silent: (payload['silent'] as bool?) ?? false,
      route: (payload['route'] as String?),
      payload: payload,
      source: NotificationSource(ruleId: ruleId, featureId: featureId, origin: origin),
    );
  }
}

/// ตัวรัน ActionSpec เบื้องต้น (ผูกกับ InAppNotifier + callback จากเลเยอร์ UI)
class ActionExecutor {
  ActionExecutor({
    required this.notifier,
    required this.openRoute,
    required this.pushSurfaceCard,
    String Function()? idGen,
  }) : _idGen = idGen;

  final InAppNotifier notifier;
  final RouteOpener openRoute;
  final SurfaceCardPusher pushSurfaceCard;
  final String Function()? _idGen;

  /// รันทีละรายการ
  Future<void> execute(ActionSpec a, {String? ruleId, String? featureId}) async {
    switch (a.type) {
      case 'notify':
        final item = notifier.fromNotifyAction(
          a,
          idGen: _idGen,
          ruleId: ruleId,
          featureId: featureId,
        );
        notifier.add(item);
        // หมายเหตุ: ถ้าต้องการยิง system notification จริง ค่อยต่อปลั๊กอินที่นี่
        break;

      case 'open_route':
        final route = a.payload?['route']?.toString() ?? '/';
        final args = (a.payload?['args'] as Map?)?.cast<String, dynamic>();
        await openRoute(route, args);
        break;

      case 'surface_card':
        final fid = a.payload?['feature_id']?.toString() ?? 'for_you';
        final cid = a.payload?['card_id']?.toString() ?? 'generic';
        final extra = (a.payload?['extra'] as Map?)?.cast<String, dynamic>();
        pushSurfaceCard(fid, cid, extra);
        break;

      case 'log':
        if (kDebugMode) {
          // ignore: avoid_print
          print('[ActionExecutor/log] ${a.title ?? ''} ${a.body ?? ''} ${a.payload ?? ''}');
        }
        break;

      default:
        if (kDebugMode) {
          // ignore: avoid_print
          print('[ActionExecutor] Unknown action type: ${a.type}');
        }
    }
  }

  /// รันหลายรายการตามลำดับ (เช่น notify แล้วค่อย open route)
  Future<void> executeAll(Iterable<ActionSpec> actions,
      {String? ruleId, String? featureId}) async {
    for (final a in actions) {
      await execute(a, ruleId: ruleId, featureId: featureId);
    }
  }
}
