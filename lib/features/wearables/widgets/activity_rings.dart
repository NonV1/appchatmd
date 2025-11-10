import 'dart:math' as math;
import 'package:flutter/material.dart';

class ActivityRingSpec {
  ActivityRingSpec({
    required this.value,
    required this.goal,
    required this.color,
    this.gap = 10,
  });

  final double value;
  final double goal;
  final Color color;
  final double gap;

  double get pct => goal <= 0 ? 0 : (value / goal).clamp(0, 1);
}

class ActivityRings extends StatelessWidget {
  const ActivityRings({
    super.key,
    required this.rings, // ส่ง 1–3 วงได้
    this.size = 160,
    this.stroke = 14,
  });

  final List<ActivityRingSpec> rings;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingsPainter(
          rings: rings,
          stroke: stroke,
          baseColor: cs.onSurface.withOpacity(.08),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.rings,
    required this.stroke,
    required this.baseColor,
  });

  final List<ActivityRingSpec> rings;
  final double stroke;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = (math.min(size.width, size.height) - stroke) / 2;

    // ไล่วงจากนอกเข้าใน
    for (int i = 0; i < rings.length; i++) {
      final spec = rings[i];
      final r = maxR - i * (stroke + 8);

      final rect = Rect.fromCircle(center: c, radius: r);
      final bg = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = baseColor;

      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bg);

      final fg = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = spec.color;

      final sweep = 2 * math.pi * spec.pct;
      canvas.drawArc(rect, -math.pi / 2, sweep, false, fg);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.rings != rings || old.stroke != stroke || old.baseColor != baseColor;
}
