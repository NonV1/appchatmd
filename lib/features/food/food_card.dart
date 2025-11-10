// lib/features/food/food_card.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FoodPreview {
  final int calories;      // today kcal
  final int goalCalories;  // goal kcal
  final int carbsG;        // g
  final int proteinG;      // g
  final int fatG;          // g

  const FoodPreview({
    required this.calories,
    required this.goalCalories,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
  });
}

class FoodCard extends StatelessWidget {
  const FoodCard({
    super.key,
    required this.data,
    this.onOpen,
    this.useBlur = false,
    this.reduceMotion = false,
  });

  final FoodPreview data;
  final VoidCallback? onOpen;
  final bool useBlur;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    final pct = (data.goalCalories <= 0)
        ? 0.0
        : (data.calories / data.goalCalories).clamp(0.0, 1.0);

    return InkWell(
      borderRadius: t.radius,
      onTap: onOpen,
      child: Glass.panel(
        t: t,
        elevated: true,
        useBlur: useBlur,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // วงแหวนแคลอรี่
            SizedBox(
              width: 82,
              height: 82,
              child: _KcalRing(
                value: pct,
                color: t.primary,
                track: t.glassBorder,
                textColor: Theme.of(context).colorScheme.onSurface,
                reduceMotion: reduceMotion,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${data.calories}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: t.primary)),
                    Text('kcal',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.65))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ข้อความ + แมคโคร
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text('Food',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.55)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Goal ${data.goalCalories} kcal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7)),
                  ),
                  const SizedBox(height: 10),

                  // Macros chips
                  Row(
                    children: [
                      _MacroChip(
                        label: 'Carbs',
                        value: '${data.carbsG}g',
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 8),
                      _MacroChip(
                        label: 'Protein',
                        value: '${data.proteinG}g',
                        color: AppTheme.tokensOf(context).success,
                      ),
                      const SizedBox(width: 8),
                      _MacroChip(
                        label: 'Fat',
                        value: '${data.fatG}g',
                        color: AppTheme.tokensOf(context).warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.72),
                    )),
            const SizedBox(height: 2),
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

class _KcalRing extends StatefulWidget {
  const _KcalRing({
    required this.value,
    required this.color,
    required this.track,
    required this.textColor,
    required this.center,
    required this.reduceMotion,
  });

  final double value; // 0..1
  final Color color;
  final Color track;
  final Color textColor;
  final Widget center;
  final bool reduceMotion;

  @override
  State<_KcalRing> createState() => _KcalRingState();
}

class _KcalRingState extends State<_KcalRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration:
        widget.reduceMotion ? const Duration(milliseconds: 0) : const Duration(milliseconds: 800),
  )..forward();

  @override
  void didUpdateWidget(covariant _KcalRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.reduceMotion && oldWidget.value != widget.value) {
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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final p = Curves.easeOutCubic.transform(_ctrl.value) * widget.value;
        return CustomPaint(
          painter: _RingPainter(
            progress: p,
            color: widget.color,
            track: widget.track,
          ),
          child: Center(child: widget.center),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress; // 0..1
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 10.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final r = math.min(size.width, size.height) / 2 - stroke / 2;

    final bg = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, r, bg);

    final fg = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.15), color, color],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    final start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), start, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
