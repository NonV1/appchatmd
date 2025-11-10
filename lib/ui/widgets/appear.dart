// lib/ui/widgets/appear.dart
import 'package:flutter/material.dart';
import '../style/motion.dart';

class Appear extends StatelessWidget {
  const Appear({super.key, required this.child, this.delay = Duration.zero});
  final Widget child; final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.medium + delay,
      curve: Motion.curve,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
