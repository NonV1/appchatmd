import 'package:flutter/material.dart';

/// ปุ่มหลักของแอป:
/// - รองรับสถานะ loading
/// - กำหนด fullWidth / ไอคอนนำหน้าได้
/// - ใช้สไตล์จาก Theme (ElevatedButtonTheme) ที่เราตั้งไว้
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.margin,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;
  final bool fullWidth;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: loading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  height: 18,
                  width: 18,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : _buildLabel(icon, label),
        ),
      ),
    );

    return margin == null ? btn : Padding(padding: margin!, child: btn);
  }

  Widget _buildLabel(Widget? icon, String label) {
    if (icon == null) return Text(label, key: const ValueKey('text'));
    return Row(
      key: const ValueKey('row'),
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}
