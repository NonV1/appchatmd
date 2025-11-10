// lib/features/fit/fit_card.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter/foundation.dart' show listEquals;

class FitPreview {
  final int activeMinutes;   // วันนี้เคลื่อนไหวกี่นาที
  final int calories;        // Today kcal
  final int sessions;        // วันนี้ออกกำลังกายกี่ครั้ง
  final List<double> trend;  // ค่าเทรนด์ 7–14 จุด สำหรับสปาร์คไลน์

  const FitPreview({
    required this.activeMinutes,
    required this.calories,
    required this.sessions,
    required this.trend,
  });
}

class FitCard extends StatelessWidget {
  const FitCard({
    super.key,
    required this.data,
    this.onOpen,
    this.useBlur = false,
    this.reduceMotion = false,
  });

  final FitPreview data;
  final VoidCallback? onOpen;
  final bool useBlur;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);

    return InkWell(
      borderRadius: t.radius,
      onTap: onOpen,
      child: Glass.panel(
        t: t,
        useBlur: useBlur,
        elevated: true,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _NeumoIcon(
                  icon: Icons.fitness_center_rounded,
                  color: t.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Fit',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 12),

            // Sparkline
            SizedBox(
              height: 42,
              child: _Sparkline(
                points: data.trend,
                color: t.primary,
                reduceMotion: reduceMotion,
              ),
            ),
            const SizedBox(height: 12),

            // Stats row (3 chips)
            Row(
              children: [
                _StatChip(
                  label: 'Active',
                  value: '${data.activeMinutes}m',
                  color: t.success,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Calories',
                  value: '${data.calories}',
                  color: t.warning,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Sessions',
                  value: '${data.sessions}',
                  color: t.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: t.radius,
          color: Colors.white.withOpacity(0.12),
          border: Border.all(color: t.glassBorder),
        ),
        child: Column(
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// ไอคอนนูน ๆ แนว Neumorphic เบา ๆ (ไม่ใช้แพ็กเกจนอก)
class _NeumoIcon extends StatelessWidget {
  const _NeumoIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(2, 3),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(-2, -2),
            spreadRadius: -2,
          ),
        ],
        border: Border.all(color: t.glassBorder),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: color),
    );
  }
}

/// Sparkline วาดเอง (เล็ก/ลื่น/กินทรัพยากรต่ำ)
class _Sparkline extends StatefulWidget {
  const _Sparkline({
    required this.points,
    required this.color,
    required this.reduceMotion,
  });

  final List<double> points;
  final Color color;
  final bool reduceMotion;

  @override
  State<_Sparkline> createState() => _SparklineState();
}

class _SparklineState extends State<_Sparkline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.reduceMotion ? const Duration(milliseconds: 0) : const Duration(milliseconds: 700),
    )..forward();
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant _Sparkline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.reduceMotion && ! listEquals(oldWidget.points, widget.points)) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    return AnimatedBuilder(
      animation: _curve,
      builder: (_, __) {
        return CustomPaint(
          painter: _SparkPainter(
            points: widget.points,
            color: widget.color,
            progress: _curve.value,
            fade: t.onSurface.withOpacity(0.08),
          ),
        );
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  final double progress; // 0..1
  final Color fade;

  _SparkPainter({
    required this.points,
    required this.color,
    required this.progress,
    required this.fade,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final minV = points.reduce(math.min);
    final maxV = points.reduce(math.max);
    final span = (maxV - minV).clamp(1e-6, 1e9);

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final t = i / (points.length - 1);
      if (t > progress) break;
      final x = t * size.width;
      final y = size.height - ((points[i] - minV) / span) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // เส้นหลัก
    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    // เงาเบา ๆ
    final shadow = Paint()
      ..color = color.withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, shadow);

    // พื้นจาง
    final fillPath = Path.from(path)
      ..lineTo(size.width * progress, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.16), fade],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.progress != progress;
  }
}
