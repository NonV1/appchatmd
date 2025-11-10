import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// การ์ดฟีเจอร์แบบ glass ใช้ซ้ำได้ทุกโมดูล
/// - รองรับ title / subtitle / icon หรือ leading widget
/// - วาง child (เช่น mini chart / metrics chips) ด้านล่าง
/// - แตะได้ (onTap) พร้อมเอฟเฟกต์ ink เบา ๆ
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.badges,
    this.child,
    this.onTap,
    this.useBlur = false,
    this.elevated = true,
    this.padding,
    this.blurSigma = 12,
    this.showModuleFrame = false,
  });

  /// 🔹 เพิ่ม named constructor สำหรับเรียก FeatureCard.glass(...)
  const FeatureCard.glass({
    Key? key,
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? leading,
    Widget? trailing,
    List<Widget>? badges,
    Widget? child,
    VoidCallback? onTap,
    EdgeInsets? padding,
    bool blur = true,
    bool elevated = true,
    double blurSigma = 12,
    bool showModuleFrame = false,
  }) : this(
          title: title,
          subtitle: subtitle,
          icon: icon,
          leading: leading,
          trailing: trailing,
          badges: badges,
          child: child,
          onTap: onTap,
          useBlur: blur,
          elevated: elevated,
          blurSigma: blurSigma,
          showModuleFrame: showModuleFrame,
          padding: padding ?? const EdgeInsets.all(14),
        );

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget>? badges;
  final Widget? child;
  final VoidCallback? onTap;

  final bool useBlur;
  final bool elevated;
  final EdgeInsets? padding;
  final double blurSigma;
  final bool showModuleFrame;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null)
          leading!
        else if (icon != null)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: t.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: t.primary),
          ),
        if (leading != null || icon != null) const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              if (badges != null && badges!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: badges!,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        if (child != null) ...[
          const SizedBox(height: 12),
          child!,
        ],
      ],
    );

    final card = Glass.panel(
      t: t,
      useBlur: useBlur,
      blurSigma: blurSigma,
      elevated: elevated,
      padding: padding ?? const EdgeInsets.all(14),
      child: body,
    );

    // ✅ แปลง BorderRadiusGeometry -> BorderRadius ป้องกัน type error
    final br = (t.radius is BorderRadius)
        ? t.radius as BorderRadius
        : BorderRadius.circular(14);

    final framed = showModuleFrame
        ? Container(
            margin: const EdgeInsets.all(4),
            // แผ่นรองโปร่งบางให้พื้นที่การ์ดชัดเจนขึ้น
            decoration: BoxDecoration(
              borderRadius: br,
              color: Colors.white.withOpacity(0.06),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(0, 0, 0, 0).withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: t.onSurface.withOpacity(0.22), // เส้นนอกเข้มเล็กน้อย
                width: 1.4,
              ),
            ),
            child: Container(
              // เส้นในสีขาวโปร่งให้ฟีล glass bevel
              decoration: BoxDecoration(
                borderRadius: br,
                border: Border.all(
                  color: Colors.white.withOpacity(0.30),
                  width: 1.0,
                ),
              ),
              child: card,
            ),
          )
        : card;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: br,
          onTap: onTap,
          child: framed,
        ),
      ),
    );
  }
}

/// ชิปสไตล์ glass เบา ๆ ใช้กับ [FeatureCard.badges]
class GlassChip extends StatelessWidget {
  const GlassChip(this.label, {super.key, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.surface.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: t.onSurface.withOpacity(0.8)),
            const SizedBox(width: 6),
          ],
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
