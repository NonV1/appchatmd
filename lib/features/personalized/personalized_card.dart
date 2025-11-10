// lib/features/personalized/personalized_card.dart
import 'package:flutter/material.dart';
import '../../features/auth/widgets/glass_card.dart';
import 'personalized_engine.dart';

/// การ์ด “For You” — แสดงคำแนะนำเฉพาะบุคคล 2–4 รายการ
class PersonalizedCard extends StatelessWidget {
  const PersonalizedCard({
    super.key,
    required this.items,     // List<ForYouEntry>
    this.onSeeAll,           // ปุ่ม See all (ออปชัน)
    this.title = 'For You',
    this.maxItems = 3,       // จำกัดเพื่อความโปร่ง
  });

  final List<ForYouEntry> items;
  final VoidCallback? onSeeAll;
  final String title;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(maxItems).toList(growable: false);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: onSeeAll, // แตะพื้นที่บนๆ = see all ก็ได้
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            Text(
              'No personal suggestions yet',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: _fg40(context)),
            )
          else
            ...visible.map((e) => _item(context, e)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        _circleIcon(context, Icons.auto_awesome),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See all'),
          ),
      ],
    );
  }

  Widget _item(BuildContext context, ForYouEntry e) {
    final color = Theme.of(context).colorScheme.primary;
    Future<Object?> onTap() => Navigator.of(context).pushNamed(e.routeName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
              ),
              alignment: Alignment.center,
              child: Icon(
                IconData(e.icon, fontFamily: 'MaterialIcons'),
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _titleSubtitle(context, e.title, e.subtitle),
            ),
            Icon(Icons.chevron_right, color: _fg40(context)),
          ],
        ),
      ),
    );
  }

  Widget _titleSubtitle(BuildContext context, String t, String s) {
    final titleStyle = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(fontWeight: FontWeight.w600);
    final subStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: _fg60(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: titleStyle),
        const SizedBox(height: 2),
        Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: subStyle),
      ],
    );
  }

  Widget _circleIcon(BuildContext context, IconData icon) {
    final bg = Theme.of(context).colorScheme.primary.withOpacity(0.12);
    final fg = Theme.of(context).colorScheme.primary;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: fg),
    );
  }

  static Color _fg40(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
  static Color _fg60(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);
}
