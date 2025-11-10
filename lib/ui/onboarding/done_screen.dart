import 'package:flutter/material.dart';
import '../../features/auth/widgets/glass_card.dart';

class DoneScreen extends StatelessWidget {
  const DoneScreen({super.key, this.onEnterApp});

  final VoidCallback? onEnterApp;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GlassCard(
                blurSigma: 10,
                elevation: 8,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: t.colorScheme.primary, size: 56),
                    const SizedBox(height: 12),
                    Text('ตั้งค่าเสร็จแล้ว',
                        style: t.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'ขอบคุณที่ให้ข้อมูล เราจะปรับคำแนะนำและการ์ด “เฉพาะคุณ” ให้เหมาะกับสุขภาพของคุณ',
                      style: t.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          if (onEnterApp != null) {
                            onEnterApp!();
                          } else {
                            // ดีฟอลต์กลับไปหน้าแรก
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          }
                        },
                        child: const Text('เข้าใช้งานแอป'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
