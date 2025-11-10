// lib/ui/style/motion.dart
import 'package:flutter/material.dart';

class Motion {
  Motion._();

  static bool reduced = false; // อัปเดตจาก Settings

  static Duration d100 = const Duration(milliseconds: 100);
  static Duration d150 = const Duration(milliseconds: 150);
  static Duration d200 = const Duration(milliseconds: 200);
  static Duration d250 = const Duration(milliseconds: 250);
  static Curve curve = Curves.easeOutCubic;

  static Duration get short => reduced ? Duration.zero : d150;
  static Duration get medium => reduced ? Duration.zero : d200;
  static Duration get long => reduced ? Duration.zero : d250;
}
