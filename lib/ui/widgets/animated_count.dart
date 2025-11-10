// lib/ui/widgets/animated_count.dart
import 'package:flutter/material.dart';
import '../style/motion.dart';

class AnimatedCount extends StatelessWidget {
  const AnimatedCount({super.key, required this.to, this.suffix = '', this.precision = 0, this.style});
  final num to; final String suffix; final int precision; final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: to.toDouble()),
      duration: Motion.medium,
      curve: Motion.curve,
      builder: (_, v, __) => Text('${v.toStringAsFixed(precision)}$suffix', style: style),
    );
  }
}
