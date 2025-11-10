// lib/features/personalized/widgets/recommendation_tile.dart
import 'package:flutter/material.dart';

import '../personalized_engine.dart' show ForYouEntry;
import '../models/personalized_event.dart' show PersonalizedEvent;

/// ไทล์คำแนะนำ (ใช้ใน For You / Personalized)
/// - เบา ไม่ใช้ blur เพื่อลดโหลดเครื่องรุ่นเก่า
/// - ปรับสไตล์ตาม theme ได้ (minimal / glass-parent จัดที่ชั้นบน)
class RecommendationTile extends StatelessWidget {
  const RecommendationTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.iconCodePoint,
    this.onTap,
    this.trailing,
    this.compact = false,
    this.border = true,
  });

  /// สร้างจาก ForYouEntry
  factory RecommendationTile.fromEntry(
    ForYouEntry e, {
    Key? key,
    VoidCallback? onTap,
    bool compact = false,
    bool border = true,
  }) {
    return RecommendationTile(
      key: key,
      title: e.title,
      subtitle: e.subtitle,
      iconCodePoint: e.icon,
      onTap: onTap,
      compact: compact,
      border: border,
    );
  }

  /// สร้างจาก PersonalizedEvent
  factory RecommendationTile.fromEvent(
    PersonalizedEvent e, {
    Key? key,
    VoidCallback? onTap,
    bool compact = false,
    bool border = true,
  }) {
    return RecommendationTile(
      key: key,
      title: e.title,
      subtitle: e.subtitle,
      iconCodePoint: e.iconCodePoint,
      onTap: onTap,
      compact: compact,
      border: border,
    );
  }

  final String title;
  final String subtitle;
  final int? iconCodePoint;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// โหมด compact → ระยะห่าง/ขนาดไอคอนเล็กลง
  final bool compact;

  /// แสดงเส้นขอบเบา ๆ เพื่อความโปร่ง (ปิดได้ถ้ามี parent glass การ์ด)
  final bool border;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface60 = cs.onSurface.withOpacity(0.75);
    final onSurface40 = cs.onSurface.withOpacity(0.6);

    final padV = compact ? 8.0 : 10.0;
    final radius = BorderRadius.circular(14);

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: padV, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: border
              ? Border.all(color: Theme.of(context).dividerColor.withOpacity(0.18))
              : null,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.35),
        ),
        child: Row(
          children: [
            _leadingIcon(context),
            const SizedBox(width: 10),
            Expanded(child: _titleSubtitle(context, onSurface60, onSurface40)),
            const SizedBox(width: 6),
            trailing ??
                Icon(Icons.chevron_right,
                    size: compact ? 18 : 22, color: onSurface40),
          ],
        ),
      ),
    );
  }

  Widget _leadingIcon(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.primary.withOpacity(0.12);
    final fg = cs.primary;

    final size = compact ? 30.0 : 34.0;
    final iconSize = compact ? 16.0 : 18.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        iconCodePoint != null
            ? IconData(iconCodePoint!, fontFamily: 'MaterialIcons')
            : Icons.auto_awesome,
        color: fg,
        size: iconSize,
      ),
    );
  }

  Widget _titleSubtitle(
      BuildContext context, Color titleColor, Color subColor) {
    final tStyle = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(fontWeight: FontWeight.w600, color: titleColor);
    final sStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(color: subColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: tStyle),
        const SizedBox(height: 2),
        Text(subtitle,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: sStyle),
      ],
    );
  }
}
