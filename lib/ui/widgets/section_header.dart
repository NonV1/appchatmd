import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:chatmd_v1/theme/app_theme.dart';

/// หัวข้อส่วนต่าง ๆ ของหน้า (มี title, subtitle, ปุ่ม See all ได้)
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
    this.padding,
    this.animate = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final EdgeInsetsGeometry? padding;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    final cs = Theme.of(context).colorScheme;

    Widget content = Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: t.spacing.horizontal / 2, vertical: 8),
      child: Row(
        children: [
          // แถบไกด์เล็ก ๆ ให้ฟีล minimal premium
          Container(
            width: 6,
            height: 24,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 10),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ],
            ),
          ),
          // See all (ถ้ามี)
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(0, 0),
              ),
              child: const Text('See all'),
            ),
        ],
      ),
    );

    if (animate) {
      content = content
          .animate()
          .fadeIn(duration: 220.ms, curve: Curves.easeOut)
          .moveY(begin: 8, end: 0, duration: 240.ms, curve: Curves.easeOut);
    }

    return content;
  }
}
