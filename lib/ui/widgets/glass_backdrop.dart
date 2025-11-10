import 'dart:ui';
import 'package:flutter/material.dart';

/// เลเยอร์พื้นหลังแบบไล่เฉด + ไฮไลต์วงกลมเบา ๆ
/// - ไม่ใช้ blur โดยตรง (ประหยัดสเปก) แต่ยังดู “ใส”
/// - เลือกเปิด blur เพิ่มได้เฉพาะหน้า high-end (optional)
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({
    super.key,
    this.useBlur = false,
    this.blurSigma = 28,
    this.gradient,
    this.children = const <Widget>[],
  });

  /// เปิด/ปิด blur ทั้งฉากหลัง (ระวังสเปกเครื่องรุ่นเก่า)
  final bool useBlur;
  final double blurSigma;

  /// กำหนด gradient เองได้ (ถ้าไม่กำหนด จะใช้ดีฟอลต์โทนม่วงน้ำเงิน)
  final Gradient? gradient;

  /// วิดเจ็ตที่จะทับลงบนแบ็คดรอป (เช่น ListView/หน้าเนื้อหา)
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = Container(
      decoration: BoxDecoration(
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withOpacity(0.14),
                cs.surface.withOpacity(0.05),
              ],
            ),
      ),
    );

    // ไฮไลต์วงกลมโปร่งบาง ๆ สองมุม (วาดด้วย Paint-less)
    final glow1 = Positioned(
      top: -80,
      left: -40,
      child: _softCircle(color: cs.primary.withOpacity(0.20), size: 220),
    );
    final glow2 = Positioned(
      bottom: -100,
      right: -60,
      child: _softCircle(color: cs.primaryContainer.withOpacity(0.25), size: 260),
    );

    Widget layer = Stack(
      children: [
        bg,
        glow1,
        glow2,
        ...children,
      ],
    );

    // ใส่ blur ทั้งฉากหลัง (ปิดได้เพื่อประหยัด)
    if (useBlur) {
      layer = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: layer,
        ),
      );
    }

    // กันรีเพนท์ทั้งฉากหลัง
    return RepaintBoundary(child: layer);
  }

  Widget _softCircle({required Color color, required double size}) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // ขอบนอกจาง ๆ ให้ดูเป็น “กลาส”
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0.0)],
          ),
        ),
      ),
    );
  }
}
