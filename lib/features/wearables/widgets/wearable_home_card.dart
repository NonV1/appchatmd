import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'activity_rings.dart';
import '../../../core/models/wearable_metrics.dart';
import '../../../utils/format.dart' as fmt;

class WearableHomeCard extends StatelessWidget {
  const WearableHomeCard({
    super.key,
    required this.metrics,   // Map<String,num> จาก WearableMetricsSnapshot.metrics
    this.onTap,
  });

  final Map<String, num> metrics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // เลือก 3 วงจากข้อมูลที่ “มีจริง”
    final energy = metrics[MetricIds.activeEnergyKcal]?.toDouble();
    final steps  = metrics[MetricIds.steps]?.toDouble();
    final sleepS = metrics[MetricIds.sleepSec]?.toDouble();

    // เป้าหมายง่าย ๆ (อนาคตดึงจากโปรไฟล์ผู้ใช้)
    const kcalGoal = 500.0;
    const stepsGoal = 6000.0;
    const sleepGoal = 8 * 3600.0;

    final rings = <ActivityRingSpec>[
      if (energy != null)
        ActivityRingSpec(value: energy, goal: kcalGoal, color: cs.primary),
      if (steps != null)
        ActivityRingSpec(value: steps, goal: stepsGoal, color: Colors.green),
      if (sleepS != null)
        ActivityRingSpec(value: sleepS, goal: sleepGoal, color: Colors.cyan),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: GlassContainer(
        blur: 8,
        borderRadius: BorderRadius.circular(18),
        color: cs.surface.withOpacity(.6),
        border: Border.all(color: cs.onSurface.withOpacity(.08)),
        shadowColor: Colors.black.withOpacity(.12),
        shadowStrength: 6,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // วงแหวน
              ActivityRings(rings: rings, size: 120, stroke: 12),
              const SizedBox(width: 14),
              // ค่าสรุปตัวหนังสือ (เฉพาะที่มีจริง)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wearable', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (metrics[MetricIds.heartRate] != null)
                      _statLine('Heart rate', fmt.fmtBpm(metrics[MetricIds.heartRate]!)),
                    if (energy != null)
                      _statLine('Energy', fmt.fmtKcal(energy)),
                    if (steps != null)
                      _statLine('Steps', fmt.fmtSteps(steps)),
                    if (sleepS != null)
                      _statLine('Sleep', fmt.fmtHCompact(Duration(seconds: sleepS.toInt()))),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _statLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
