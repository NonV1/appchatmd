// lib/features/fit/screens/fit_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../fit_card.dart';

class FitScreen extends StatefulWidget {
  const FitScreen({super.key, this.reduceMotion = false, this.useBlur = false});

  final bool reduceMotion;
  final bool useBlur;

  @override
  State<FitScreen> createState() => _FitScreenState();
}

class _FitScreenState extends State<FitScreen>
    with SingleTickerProviderStateMixin {
  // TODO: ต่อข้อมูลจริงจาก HealthRepo/FitRepo
  late FitPreview _today = const FitPreview(
    activeMinutes: 46,
    calories: 320,
    sessions: 2,
    trend: [10, 18, 9, 22, 17, 30, 26, 35, 40, 38, 44],
  );

  // สัปดาห์ย้อนหลัง (7 วัน)
  List<int> _weekActive = [30, 55, 42, 0, 68, 25, 61];

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration:
        widget.reduceMotion ? const Duration(milliseconds: 0) : const Duration(milliseconds: 800),
  )..forward();

  Future<void> _refresh() async {
    // TODO: ดึงข้อมูลจริงแล้วเซ็ต state
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      // สลับค่าเล่น ๆ
      _today = FitPreview(
        activeMinutes: _today.activeMinutes + 2,
        calories: _today.calories + 15,
        sessions: _today.sessions,
        trend: [..._today.trend.skip(1), _today.trend.last + 3],
      );
      _weekActive = List<int>.from(_weekActive)
        ..[math.Random().nextInt(_weekActive.length)] += 5;
    });
    if (!widget.reduceMotion) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fit'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: t.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // สรุปวันนี้ (ใช้การ์ดเดียวกับ Home)
            FitCard(
              data: _today,
              useBlur: widget.useBlur,
              reduceMotion: widget.reduceMotion,
              onOpen: () {}, // already here
            ),
            const SizedBox(height: 16),

            // กราฟสัปดาห์
            Text('This week',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Glass.panel(
              t: t,
              useBlur: widget.useBlur,
              elevated: true,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: SizedBox(
                height: 160,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: _BarsPainter(
                        values: _weekActive,
                        progress: _ctrl.value,
                        barColor: t.primary,
                        gridColor: t.glassBorder,
                        textColor:
                            Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // รายการเซสชันล่าสุด (mock)
            Text('Recent sessions',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ...[
              _SessionTile(
                icon: Icons.directions_run_rounded,
                title: 'Evening Run',
                subtitle: '22 mins · 180 kcal',
                color: t.success,
              ),
              _SessionTile(
                icon: Icons.fitness_center_rounded,
                title: 'Strength',
                subtitle: '30 mins · 140 kcal',
                color: t.primary,
              ),
              _SessionTile(
                icon: Icons.pedal_bike_rounded,
                title: 'Cycling',
                subtitle: '18 mins · 90 kcal',
                color: t.warning,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass.panel(
        t: t,
        useBlur: false,
        elevated: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.18),
                border: Border.all(color: t.glassBorder),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.progress,
    required this.barColor,
    required this.gridColor,
    required this.textColor,
  });

  final List<int> values;   // 7 ค่า
  final double progress;    // 0..1 สำหรับอนิเมชัน
  final Color barColor;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = (values.reduce(math.max)).clamp(1, 10000);
    final paintGrid = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke;

    // เส้นกริด 3 เส้น
    final rows = 3;
    for (int i = 1; i <= rows; i++) {
      final y = size.height * i / (rows + 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final n = values.length;
    final barW = size.width / (n * 1.8);
    final gap = (size.width - barW * n) / (n - 1);

    final barPaint = Paint()
      ..color = barColor.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final x = i * (barW + gap);
      final t = i / (n - 1);
      if (t > progress) break;

      final h = size.height * (values[i] / maxVal) * progress;
      final r = RRect.fromLTRBR(
        x,
        size.height - h,
        x + barW,
        size.height,
        const Radius.circular(8),
      );
      canvas.drawRRect(r, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.progress != progress;
  }
}
