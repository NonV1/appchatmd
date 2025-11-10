// lib/features/food/screens/food_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../food_card.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key, this.useBlur = false, this.reduceMotion = false});

  final bool useBlur;
  final bool reduceMotion;

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen>
    with SingleTickerProviderStateMixin {
  // TODO: ต่อข้อมูลจริงจาก FoodRepo/APIs
  FoodPreview _today = const FoodPreview(
    calories: 980,
    goalCalories: 1800,
    carbsG: 160,
    proteinG: 58,
    fatG: 32,
  );

  // kcal ต่อมื้อ (Breakfast / Lunch / Dinner / Snack)
  List<int> _meals = [320, 410, 220, 120];

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration:
        widget.reduceMotion ? const Duration(milliseconds: 0) : const Duration(milliseconds: 800),
  )..forward();

  Future<void> _refresh() async {
    // mock refresh
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _today = FoodPreview(
        calories: _today.calories + 60,
        goalCalories: _today.goalCalories,
        carbsG: _today.carbsG + 10,
        proteinG: _today.proteinG + 4,
        fatG: _today.fatG + 2,
      );
      _meals = List<int>.from(_meals)
        ..[math.Random().nextInt(_meals.length)] += 50;
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
    final pct = (_today.goalCalories == 0)
        ? 0.0
        : (_today.calories / _today.goalCalories).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Food')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: t.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // แหวนใหญ่ + ตัวเลข
            Glass.panel(
              t: t,
              elevated: true,
              useBlur: widget.useBlur,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: _BigRing(
                      value: pct,
                      color: t.primary,
                      track: t.glassBorder,
                      reduceMotion: widget.reduceMotion,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodyLarge!,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('${_today.calories}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(color: t.primary)),
                              const SizedBox(width: 6),
                              Text('kcal',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      )),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Goal ${_today.goalCalories} kcal',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ใช้การ์ดเดียวกับ Home เป็นสรุปย่อย
            FoodCard(
              data: _today,
              useBlur: widget.useBlur,
              reduceMotion: widget.reduceMotion,
              onOpen: () {}, // already here
            ),
            const SizedBox(height: 16),

            // กราฟต่อมื้อ
            Text('Meals',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Glass.panel(
              t: t,
              elevated: true,
              useBlur: widget.useBlur,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SizedBox(
                height: 160,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: _MealsBarPainter(
                        values: _meals,
                        progress: _ctrl.value,
                        barColor: t.primary,
                        gridColor: t.glassBorder,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _mealLabel(context, 'Breakfast'),
                              _mealLabel(context, 'Lunch'),
                              _mealLabel(context, 'Dinner'),
                              _mealLabel(context, 'Snack'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recent items (mock)
            Text('Recent items',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _FoodTile(
              emoji: '🥗',
              title: 'Chicken Salad',
              subtitle: '180 kcal · 12g P · 7g C · 9g F',
              color: t.success,
            ),
            _FoodTile(
              emoji: '🍚',
              title: 'Rice Bowl',
              subtitle: '320 kcal · 6g P · 60g C · 5g F',
              color: t.warning,
            ),
            _FoodTile(
              emoji: '🥛',
              title: 'Milk',
              subtitle: '120 kcal · 8g P · 11g C · 4g F',
              color: t.primary,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _mealLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.7),
          ),
    );
  }
}

class _BigRing extends StatefulWidget {
  const _BigRing({
    required this.value,
    required this.color,
    required this.track,
    required this.reduceMotion,
  });

  final double value; // 0..1
  final Color color;
  final Color track;
  final bool reduceMotion;

  @override
  State<_BigRing> createState() => _BigRingState();
}

class _BigRingState extends State<_BigRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration:
        widget.reduceMotion ? const Duration(milliseconds: 0) : const Duration(milliseconds: 900),
  )..forward();

  @override
  void didUpdateWidget(covariant _BigRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.reduceMotion && oldWidget.value != widget.value) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final p = Curves.easeOutCubic.transform(_ctrl.value) * widget.value;
        return CustomPaint(
          painter: _RingPainter(progress: p, color: widget.color, track: widget.track),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress; // 0..1
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 14.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final r = math.min(size.width, size.height) / 2 - stroke / 2;

    final bg = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, r, bg);

    final fg = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.18), color, color],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    final start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), start, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _MealsBarPainter extends CustomPainter {
  _MealsBarPainter({
    required this.values,
    required this.progress,
    required this.barColor,
    required this.gridColor,
  });

  final List<int> values; // 4 meals
  final double progress;  // 0..1
  final Color barColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.reduce(math.max).clamp(1, 100000);
    final grid = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke;

    // grid lines (3)
    final rows = 3;
    for (int i = 1; i <= rows; i++) {
      final y = size.height * i / (rows + 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final n = values.length;
    final barW = size.width / (n * 2.2);
    final gap = (size.width - barW * n) / (n - 1);

    final bar = Paint()
      ..color = barColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final x = i * (barW + gap);
      final h = size.height * (values[i] / maxVal) * progress;
      final r = RRect.fromLTRBR(
        x,
        size.height - h,
        x + barW,
        size.height,
        const Radius.circular(10),
      );
      canvas.drawRRect(r, bar);
    }
  }

  @override
  bool shouldRepaint(covariant _MealsBarPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.progress != progress;
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String emoji;
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
        elevated: true,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.14),
                border: Border.all(color: t.glassBorder),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.55)),
          ],
        ),
      ),
    );
  }
}
