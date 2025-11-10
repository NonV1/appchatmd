// lib/features/wearables/screens/wearable_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

import '../../../core/data/health_repo.dart';
import '../../../core/models/wearable_metrics.dart';
import '../../../utils/format.dart' as fmt;

class WearableScreen extends StatefulWidget {
  const WearableScreen({super.key});
  @override
  State<WearableScreen> createState() => _WearableScreenState();
}

class _WearableScreenState extends State<WearableScreen> {
  final _health = HealthRepo();

  WearableMetricsSnapshot? _snap;
  bool _loading = true;

  // series จริง (จะว่าง[] ถ้าอ่านไม่ได้)
  List<double> _hrSeries = const [];
  List<double> _stepsSeries = const [];
  List<double> _energySeries = const [];

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await _health.fetchToday();
      _snap = snap;

      // DEBUG: print snapshot metrics
      print('DEBUG: snapshot metrics = \\n${snap.metrics}');

      // ดึงซีรีส์เฉพาะตัวที่ "มีข้อมูลวันนี้"
      if (snap.metrics.containsKey(MetricIds.heartRate)) {
        _hrSeries = await _health.fetchHeartRateSeries(
          lookback: const Duration(hours: 3),
          buckets: 24,
        );
      } else {
        _hrSeries = const [];
      }

      if (snap.metrics.containsKey(MetricIds.steps)) {
        _stepsSeries = await _health.fetchStepsSeries(
          lookback: const Duration(hours: 12),
          buckets: 12,
        );
      } else {
        _stepsSeries = const [];
      }

      if (snap.metrics.containsKey(MetricIds.activeEnergyKcal)) {
        _energySeries = await _health.fetchEnergySeries(
          lookback: const Duration(hours: 12),
          buckets: 12,
        );
      } else {
        _energySeries = const [];
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
  print('DEBUG: build start');
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final m = _snap?.metrics ?? const <String, num>{};
  // DEBUG: print metrics every build
  print('DEBUG: build metrics = $m');
    final hr = m[MetricIds.heartRate];
    final steps = m[MetricIds.steps]?.toInt();
    final sleepSec = m[MetricIds.sleepSec]?.toInt();
    final kcal = m[MetricIds.activeEnergyKcal];
    final spo2 = m[MetricIds.oxygenSaturationPct];
    final fat = m[MetricIds.bodyFatPct];
    final glucose = m[MetricIds.bloodGlucoseMgdl];

    // กำหนด goal สำหรับแต่ละวงแหวน (สามารถปรับได้ตามต้องการ)
    const stepsGoal = 6000;
    const activeTimeGoal = 90; // นาที
    const kcalGoal = 500;
  // final activeTime = m[MetricIds.activeMinutes]?.toInt();
    final activityCalories = kcal?.toInt();

    return Scaffold(
      appBar: AppBar(title: const Text('Wearable insights')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroHeader(),
            const SizedBox(height: 12),

            // ===== Daily summary rings =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RingProgress(
                  value: (steps ?? 0).toDouble(),
                  goal: stepsGoal.toDouble(),
                  formatter: (v) => '${v.toInt()}\nSteps',
                ),
                _RingProgress(
                  value: (activityCalories ?? 0).toDouble(),
                  goal: kcalGoal.toDouble(),
                  formatter: (v) => '${v.toInt()}\nKcal',
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ===== Summary (เฉพาะที่อ่านได้) =====
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (hr != null)
                  _StatPill(
                    label: 'Heart rate',
                    value: fmt.fmtBpm(hr),
                    color: cs.primary,
                  ),
                if (steps != null)
                  _StatPill(
                    label: 'Steps',
                    value: fmt.fmtSteps(steps),
                    color: cs.tertiaryContainer,
                  ),
                if (sleepSec != null)
                  _StatPill(
                    label: 'Sleep',
                    value: fmt.fmtHCompact(Duration(seconds: sleepSec)),
                    color: cs.secondaryContainer,
                  ),
                if (kcal != null)
                  _StatPill(
                    label: 'Active energy',
                    value: fmt.fmtKcal(kcal),
                    color: cs.errorContainer,
                  ),
                if (spo2 != null)
                  _StatPill(
                    label: 'SpO₂',
                    value: fmt.fmtSpO2(spo2),
                    color: cs.primaryContainer,
                  ),
                if (fat != null)
                  _StatPill(
                    label: 'Body fat',
                    value: '${fat.toStringAsFixed(1)}%',
                    color: cs.secondaryContainer,
                  ),
                if (glucose != null)
                  _StatPill(
                    label: 'Glucose',
                    value: '${glucose.toStringAsFixed(0)} mg/dL',
                    color: cs.tertiaryContainer,
                  ),
              ],
            )
                .animate(delay: const Duration(milliseconds: 50))
                .fadeIn(duration: const Duration(milliseconds: 220), curve: Curves.easeOut)
                .moveY(begin: 8, end: 0, duration: const Duration(milliseconds: 240), curve: Curves.easeOut),

            const SizedBox(height: 16),

            // ===== Charts จากค่าจริง (ซ่อนถ้าไม่มีข้อมูล) =====
            if (_hrSeries.isNotEmpty) ...[
              _GlassTile(
                title: 'Heart rate trend',
                subtitle: 'Last 3 hours',
                child: _LineChartSimple(points: _hrSeries),
              ),
              const SizedBox(height: 14),
            ],
            if (_stepsSeries.isNotEmpty) ...[
              _GlassTile(
                title: 'Steps timeline',
                subtitle: 'Last 12 hours',
                child: _BarChartSimple(values: _stepsSeries),
              ),
              const SizedBox(height: 14),
            ],
            if (_energySeries.isNotEmpty) ...[
              _GlassTile(
                title: 'Active energy',
                subtitle: 'Last 12 hours',
                child: _BarChartSimple(values: _energySeries),
              ),
              const SizedBox(height: 14),
            ],

            // Sleep: ถ้ามีแค่ total ให้แสดงวงแหวน progress แทน
            if (sleepSec != null) ...[
              _GlassTile(
                title: 'Sleep total',
                subtitle: 'Last 24 hours',
                child: _RingProgress(
                  value: (sleepSec / 3600).clamp(0, 12).toDouble(),
                  goal: 8, // ชั่วโมง
                  formatter: (v) => '${v.toStringAsFixed(1)} h',
                ),
              ),
              const SizedBox(height: 14),
            ],

            // SpO2/Body fat/Glucose ไม่มีซีรีส์ใน repo ตอนนี้ → แสดงค่าเดี่ยว
            if (spo2 != null)
              _GlassTile(
                title: 'SpO₂ latest',
                subtitle: 'Today',
                child: Center(
                  child: Text(
                    fmt.fmtSpO2(spo2),
                    style: t.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            if (fat != null) ...[
              const SizedBox(height: 14),
              _GlassTile(
                title: 'Body fat',
                subtitle: 'Latest',
                child: Center(
                  child: Text(
                    '${fat.toStringAsFixed(1)}%',
                    style: t.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            if (glucose != null) ...[
              const SizedBox(height: 14),
              _GlassTile(
                title: 'Blood glucose',
                subtitle: 'Latest',
                child: Center(
                  child: Text(
                    '${glucose.toStringAsFixed(0)} mg/dL',
                    style: t.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _load,
        label: const Text('Refresh'),
        icon: const Icon(Icons.refresh),
      ),
    );
  }
}

/// ---------- Header ลายกราฟิก ----------
class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 210,
              height: 120,
              child: CustomPaint(painter: _RingsPainter(cs)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(
                label: const Text('Healthy'),
                backgroundColor: cs.primary.withOpacity(.12),
                side: BorderSide.none,
                labelStyle: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: cs.primary),
              ),
              const SizedBox(height: 8),
              Text('Overview', style: Theme.of(context).textTheme.headlineMedium),
              Text('Your latest health snapshot',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.cs);
  final ColorScheme cs;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Offset(size.width * .65, size.height * .55);
    final radii = [80.0, 64.0, 48.0, 32.0];
    final colors = [
      cs.primary,
      cs.onSurface.withOpacity(.85),
      cs.primary.withOpacity(.25),
      cs.onSurface.withOpacity(.15),
    ];
    for (int i = 0; i < radii.length; i++) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: base, radius: radii[i]),
        -1.2,
        1.7,
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ---------- Glass tile ----------
class _GlassTile extends StatelessWidget {
  const _GlassTile({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: GlassContainer(
        blur: 12,
        borderRadius: BorderRadius.circular(18),
        color: cs.surface.withOpacity(.14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.surface.withOpacity(.18), cs.primary.withOpacity(.06)],
        ),
        border: Border.all(width: 1, color: cs.onSurface.withOpacity(.12)),
        shadowStrength: 6,
        shadowColor: Colors.black.withOpacity(.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              SizedBox(height: 160, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Basic charts ----------
class _LineChartSimple extends StatelessWidget {
  const _LineChartSimple({required this.points});
  final List<double> points;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = points.isEmpty ? [0.0] : points;
    final spots = [
      for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
    ];
    double min = data.first, max = data.first;
    for (final v in data) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final minY = (min - 5).clamp(0, 999).toDouble();
    final maxY = (max + 5).toDouble();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: cs.primary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: cs.primary.withOpacity(.15),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [cs.primary.withOpacity(.22), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }
}

class _BarChartSimple extends StatelessWidget {
  const _BarChartSimple({required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bars = [
      for (int i = 0; i < values.length; i++)
        BarChartRodData(
          toY: values[i],
          width: 8,
          borderRadius: BorderRadius.circular(4),
          color: cs.primary,
        ),
    ];

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (int i = 0; i < bars.length; i++)
            BarChartGroupData(x: i, barRods: [bars[i]]),
        ],
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }
}

/// วงแหวน progress ใช้แทนกราฟเมื่อมีค่าเดียว (เช่น total sleep)
class _RingProgress extends StatelessWidget {
  const _RingProgress({
    required this.value,
    required this.goal,
    required this.formatter,
  });

  final double value; // หน่วยเดียวกับ goal
  final double goal;
  final String Function(double) formatter;

  @override
  Widget build(BuildContext context) {
    print('DEBUG: _RingProgress build value=$value goal=$goal');
    final cs = Theme.of(context).colorScheme;
    final p = goal == 0 ? 0.0 : (value / goal).clamp(0, 1).toDouble();

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            value: 1,
            strokeWidth: 12,
            color: cs.onSurface.withOpacity(.08),
          ),
        ),
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            value: p,
            strokeWidth: 12,
            color: cs.primary,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatter(value),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text('goal ${formatter(goal)}',
                style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ],
    );
  }
}

/// ---------- Pill ----------
class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 10,
      borderRadius: BorderRadius.circular(14),
      color: color.withOpacity(.10),
      border: Border.all(color: color.withOpacity(.25)),
      shadowStrength: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
