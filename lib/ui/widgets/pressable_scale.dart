// lib/ui/widgets/pressable_scale.dart
import 'package:flutter/material.dart';
import '../style/motion.dart';

class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.onTap});
  final Widget child; final VoidCallback? onTap;

  @override State<PressableScale> createState() => _S();
}
class _S extends State<PressableScale> {
  double s = 1;
  @override Widget build(_) => GestureDetector(
    onTapDown: (_) => setState(()=> s = .96),
    onTapCancel: ()=> setState(()=> s = 1),
    onTapUp: (_){ setState(()=> s = 1); widget.onTap?.call(); },
    child: AnimatedScale(scale: s, duration: Motion.short, curve: Motion.curve, child: widget.child),
  );
}
