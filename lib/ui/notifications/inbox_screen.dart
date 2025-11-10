import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/alerts/inbox_store.dart';
import '../../theme/app_theme.dart';
  
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _store = InboxStore.instance;
  final bool _useBlur = false; // อ่านจากธีม/พร็อพไฟล์อื่นๆได้ ถ้าอยากผูกกับ prefs ให้ย้ายไป Settings
  final _fmt = DateFormat('MMM d, HH:mm');

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () => _store.markAllRead(),
          ),
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.clear_all_rounded),
            onPressed: () => _confirmClearAll(context),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<NotificationItem>>(
        valueListenable: _store.listenable,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return _emptyState(context, t);
          }

          // แสดงรายการล่าสุดก่อน
          final sorted = [...items]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final n = sorted[i];
              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                background: _swipeBg(t, Icons.delete_forever_rounded),
                onDismissed: (_) {
                  // ต้องมี method remove(String id) ใน InboxStore
                  // (เราใส่ไว้แล้วในไฟล์ store)
                  _store.remove(n.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification removed')),
                  );
                },
                child: Glass.panel(
                  t: t,
                  useBlur: _useBlur,
                  elevated: !n.isRead, // อันที่ยังไม่อ่านเด้งเล็ก ๆ
                  padding: const EdgeInsets.all(12),
                  child: _tile(context, t, n),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, AppTokens t, NotificationItem n) {
    final unreadDot = !n.isRead
        ? Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: t.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: t.primary.withOpacity(0.35),
                  blurRadius: 8,
                )
              ],
            ),
          )
        : const SizedBox(width: 10, height: 10);

    final leadingIcon = Icon(
      _iconForLevel(n.level),
      color: n.isRead ? t.onSurface.withOpacity(0.6) : t.primary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leadingIcon,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวเรื่อง + เวลา
              Row(
                children: [
                  Expanded(
                    child: Text(
                      n.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fmt.format(n.createdAt),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: t.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (n.body != null && n.body!.isNotEmpty)
                Text(
                  n.body!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (n.payload != null && n.payload!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _payloadChips(context, t, n.payload!),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  unreadDot,
                  const Spacer(),
                  IconButton(
                    tooltip: n.isRead ? 'Mark as unread' : 'Mark as read',
                    icon: Icon(
                      n.isRead
                          ? Icons.mark_email_unread_outlined
                          : Icons.mark_email_read_rounded,
                    ),
                    onPressed: () => _store.markRead(n.id, read: !n.isRead),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _store.remove(n.id),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconForLevel(NotificationLevel level) {
    switch (level) {
      case NotificationLevel.warning:
        return Icons.warning_amber_rounded;
      case NotificationLevel.critical:
        return Icons.error_outline_rounded;
      case NotificationLevel.info:
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Widget _payloadChips(BuildContext context, AppTokens t, Map<String, dynamic> p) {
    final entries = p.entries.take(4); // แสดงไม่เกิน 4 อันให้ดูโปร่ง
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: t.surface.withOpacity(0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.glassBorder),
            ),
            child: Text(
              '${e.key}: ${e.value}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          )
      ],
    );
  }

  Widget _swipeBg(AppTokens t, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: t.danger.withOpacity(0.18),
        borderRadius: t.radius,
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: t.danger),
    );
  }

  Widget _emptyState(BuildContext context, AppTokens t) {
    return Center(
      child: Glass.panel(
        t: t,
        useBlur: _useBlur,
        elevated: false,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: t.onSurface.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text('No notifications',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'You’re all caught up!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      _store.clear();
    }
  }
}
