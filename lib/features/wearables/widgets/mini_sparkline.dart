// lib/features/wearables/widgets/mini_sparkline.dart
import 'package:flutter/material.dart';

class MiniSparkline extends StatelessWidget {
  const MiniSparkline({super.key, required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final data = (values.isEmpty)
        ? [70.0, 73.0, 72.0, 75.0, 80.0, 78.0, 76.0, 77.0]
        : values; // Now `values` should be a List<double> already
    final minV = data.reduce((a, b) => a < b ? a : b);
    final maxV = data.reduce((a, b) => a > b ? a : b);
    final cs = Theme.of(context).colorScheme;

    return CustomPaint(
      painter: _SparkPainter(
        values: data,
        min: minV,
        max: maxV,
        color: cs.primary,
      ),
      size: const Size(double.infinity, 38),
    );
  }
}


class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.values, required this.min, required this.max, required this.color});
  final List<double> values;
  final double min, max;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height * (1 - (values[i] - min) / ((max - min).clamp(1, 1e9)));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
