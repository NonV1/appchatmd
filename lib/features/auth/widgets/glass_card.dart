// lib/features/auth/widgets/glass_card.dart
import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.radius = 18,
    this.blurSigma = 12,
    this.backgroundOpacity = 0.12,
    this.borderOpacity = 0.22,
    this.elevation = 6,
    this.animate = true,
    this.reduceMotion = false,
    this.onTap,                          // ✅ เพิ่ม
    required this.child,
  });

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  final double radius;
  final double blurSigma;
  final double backgroundOpacity;
  final double borderOpacity;
  final double elevation;

  final bool animate;
  final bool reduceMotion;

  final VoidCallback? onTap;             // ✅ เพิ่ม
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final card = GlassContainer(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(radius),
      blur: blurSigma.clamp(0, 40).toDouble(),
      color: cs.surface.withOpacity(backgroundOpacity),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cs.surface.withOpacity(backgroundOpacity * 0.95),
          cs.primary.withOpacity(backgroundOpacity * 0.28),
        ],
      ),
      border: Border.all(
        width: 1,
        color: cs.onSurface.withOpacity(borderOpacity),
      ),
      shadowStrength: elevation,
      // ถ้าแพ็กเกจของคุณไม่มี shadowColor ให้ลบบรรทัดนี้
      shadowColor: Colors.black.withOpacity(0.10),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Colors.white.withOpacity(0.06),
              Colors.transparent,
            ],
          ),
        ),
        child: child,
      ),
    );

    // margin ภายนอก
    final withMargin = Container(margin: margin, child: card);

    // ✅ ทำให้แตะได้พร้อม ripple
    final br = BorderRadius.circular(radius);
    final tappable = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        child: withMargin,
      ),
    );

    final wrapped = RepaintBoundary(child: tappable);

    if (!animate || reduceMotion) return wrapped;

    return wrapped
        .animate()
        .fadeIn(duration: 250.ms, curve: Curves.easeOut)
        .moveY(begin: 16, end: 0, duration: 280.ms, curve: Curves.easeOut);
  }
}
