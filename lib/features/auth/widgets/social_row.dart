import 'package:flutter/material.dart';

/// ผู้ให้บริการล็อกอินแบบ Social (mock)
enum SocialProvider { apple, google, facebook }

/// callback ตอนกดปุ่ม social
typedef SocialPressed = void Function(SocialProvider provider)?;

class SocialRow extends StatelessWidget {
  const SocialRow({super.key, this.onPressed});

  final SocialPressed onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ใช้ LayoutBuilder เพื่อสเกลปุ่มให้พอดีกับจอเล็ก/ใหญ่
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        final h = isNarrow ? 44.0 : 48.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Or continue with',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    label: 'Apple',
                    icon: Icons.apple, // ถ้า SDK เก่าไม่มี ไอคอนนี้จะ fallback เป็น logo “A”
                    height: h,
                    foreground: cs.onSurface,
                    border: cs.outline.withOpacity(0.4),
                    onTap: () => onPressed?.call(SocialProvider.apple),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SocialButton(
                    label: 'Google',
                    icon: Icons.g_mobiledata_rounded, // mock ไอคอน
                    height: h,
                    foreground: cs.onSurface,
                    border: cs.outline.withOpacity(0.4),
                    onTap: () => onPressed?.call(SocialProvider.google),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SocialButton(
                    label: 'Facebook',
                    icon: Icons.facebook_rounded,
                    height: h,
                    foreground: cs.onSurface,
                    border: cs.outline.withOpacity(0.4),
                    onTap: () => onPressed?.call(SocialProvider.facebook),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.height,
    required this.foreground,
    required this.border,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final double height;
  final Color foreground;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: cs.surface.withOpacity(0.06),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ),
    );
  }
}
