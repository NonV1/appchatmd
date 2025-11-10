import 'package:flutter/foundation.dart';

import '../models/notification_item.dart';

/// ส่งออกโมเดลให้เลเยอร์ UI ใช้ต่อได้
export '../models/notification_item.dart' show NotificationItem, NotificationLevel;

/// ตัวเก็บแจ้งเตือน in-app แบบเบา ๆ (in-memory + ValueListenable)
class InboxStore {
  InboxStore._();

  static final InboxStore instance = InboxStore._();

  final ValueNotifier<List<NotificationItem>> _items =
      ValueNotifier<List<NotificationItem>>(const <NotificationItem>[]);

  ValueListenable<List<NotificationItem>> get listenable => _items;

  List<NotificationItem> get items => _items.value;

  void add(NotificationItem item) {
    _items.value = <NotificationItem>[item, ..._items.value];
  }

  void remove(String id) {
    _items.value = _items.value.where((n) => n.id != id).toList(growable: false);
  }

  void clear() {
    _items.value = const <NotificationItem>[];
  }

  void markRead(String id, {bool read = true}) {
    final updated = _items.value.map((n) {
      if (n.id != id) return n;
      if (read) return n.isRead ? n : n.markRead();
      return n.copyWith(readAt: null);
    }).toList(growable: false);
    _items.value = updated;
  }

  void markAllRead() {
    final now = DateTime.now();
    _items.value = _items.value
        .map((n) => n.isRead ? n : n.markRead(now))
        .toList(growable: false);
  }
}
