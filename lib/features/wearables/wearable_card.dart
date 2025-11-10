// lib/features/wearables/wearable_card.dart
import 'package:flutter/material.dart';

import '../../core/models/wearable_metrics.dart';
import '../../theme/app_theme.dart';

class WearableCard extends StatelessWidget {
  const WearableCard({
    super.key,
    required this.snapshot,
    this.onTap,
    this.useBlur = false,
    this.dailyStepGoal = 8000, // ปรับเป้าหมายก้าวได้
  });

  final WearableMetricsSnapshot? snapshot;
  final VoidCallback? onTap;
  final bool useBlur;
  final int dailyStepGoal;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    final s = snapshot;

    // ลำดับความสำคัญในการแสดง (เลือกได้สูงสุด 4 รายการ)
    final preferredOrder = <String>[
      MetricIds.steps,
      MetricIds.heartRate,
      MetricIds.sleepSec,
      MetricIds.oxygenSaturationPct,
      MetricIds.activeEnergyKcal,
      MetricIds.bloodGlucoseMgdl,
      MetricIds.exerciseMinutes,
    ];

    // ดึงเฉพาะ metric ที่มีจริง
    final items = <_MetricView>[];
    if (s != null && s.metrics.isNotEmpty) {
      for (final id in preferredOrder) {
        final value = s.metrics[id];
        if (value != null) {
          items.add(_toView(id, value));
        }
        if (items.length >= 4) break;
      }

      if (items.length < 4) {
        final extras = s.metrics.entries.where(
          (entry) => !preferredOrder.contains(entry.key),
        );
        for (final entry in extras) {
          items.add(_toView(entry.key, entry.value));
          if (items.length >= 4) break;
        }
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: t.radius,
      child: Glass.panel(
        t: t,
        useBlur: useBlur,
        elevated: true,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.watch_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Wearables',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ],
            ),
            const SizedBox(height: 10),

            // เนื้อหาหลัก
            if (s == null || items.isEmpty)
              _emptyState(context)
            else
              Column(
                children: [
                  // แถวแรก (2 รายการ)
                  Row(
                    children: [
                      Expanded(child: _MetricTile(items[0])),
                      const SizedBox(width: 10),
                      Expanded(child: (items.length > 1) ? _MetricTile(items[1]) : const SizedBox.shrink()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // แถวสอง (อีก 2 รายการถ้ามี)
                  Row(
                    children: [
                      Expanded(child: (items.length > 2) ? _MetricTile(items[2]) : const SizedBox.shrink()),
                      const SizedBox(width: 10),
                      Expanded(child: (items.length > 3) ? _MetricTile(items[3]) : const SizedBox.shrink()),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress (เป้าหมายก้าว/วัน)
                  _stepsProgress(context, s.steps?.toDouble() ?? 0.0),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: onSurface.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ยังไม่มีข้อมูลสวมใส่ • เปิดสิทธิ์ใน Health Connect/HealthKit เพื่อแสดงผล',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onSurface.withOpacity(0.8),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepsProgress(BuildContext context, double steps) {
    final pct = (dailyStepGoal <= 0)
        ? 0.0
        : (steps / dailyStepGoal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Steps Goal', style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            Text(
              '${steps.toStringAsFixed(0)} / $dailyStepGoal',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 6),
        // ใช้ ClipRRect + Container แทน progress หนัก ๆ
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Container(color: Theme.of(context).dividerColor.withOpacity(0.35)),
                // แท่งวิ่งนุ่ม ๆ
                LayoutBuilder(builder: (context, box) {
                  final w = box.maxWidth * pct;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    width: w,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.85),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _MetricView _toView(String id, num value) {
    switch (id) {
      case MetricIds.steps:
        return _MetricView(
          id: id,
          label: 'Steps',
          valueStr: value.toInt().toString(),
          unit: '',
          icon: Icons.directions_walk_rounded,
        );
      case MetricIds.heartRate:
        return _MetricView(
          id: id,
          label: 'Heart Rate',
          valueStr: value.toStringAsFixed(0),
          unit: 'bpm',
          icon: Icons.favorite_rounded,
        );
      case MetricIds.sleepSec:
        final h = (value ~/ 3600);
        final m = ((value % 3600) ~/ 60);
        return _MetricView(
          id: id,
          label: 'Sleep',
          valueStr: '${h}h ${m}m',
          unit: '',
          icon: Icons.nightlight_round_rounded,
        );
      case MetricIds.oxygenSaturationPct:
        return _MetricView(
          id: id,
          label: 'SpO₂',
          valueStr: value.toStringAsFixed(0),
          unit: '%',
          icon: Icons.bubble_chart_rounded,
        );
      case MetricIds.activeEnergyKcal:
        return _MetricView(
          id: id,
          label: 'Active',
          valueStr: value.toStringAsFixed(0),
          unit: 'kcal',
          icon: Icons.local_fire_department_rounded,
        );
      case MetricIds.bloodGlucoseMgdl:
        return _MetricView(
          id: id,
          label: 'Glucose',
          valueStr: value.toStringAsFixed(0),
          unit: 'mg/dL',
          icon: Icons.water_drop_outlined,
        );
      case MetricIds.nutritionEnergyKcal:
        return _MetricView(
          id: id,
          label: 'Intake',
          valueStr: value.toStringAsFixed(0),
          unit: 'kcal',
          icon: Icons.restaurant_outlined,
        );
      case MetricIds.exerciseMinutes:
        return _MetricView(
          id: id,
          label: 'Exercise',
          valueStr: value.toStringAsFixed(0),
          unit: 'min',
          icon: Icons.fitness_center_outlined,
        );
      case MetricIds.exerciseSessions:
        return _MetricView(
          id: id,
          label: 'Sessions',
          valueStr: value.toStringAsFixed(0),
          unit: '',
          icon: Icons.event_available_outlined,
        );
      default:
        return _MetricView(
          id: id,
          label: id,
          valueStr: value.toString(),
          unit: '',
          icon: Icons.analytics_outlined,
        );
    }
  }
}

/// ====== วิวแต่ละช่อง metric (เบา ลื่น และมีอนิเมชันตัวเลขนุ่ม ๆ) ======
class _MetricTile extends StatelessWidget {
  const _MetricTile(this.view);

  final _MetricView view;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);

    return Glass.panel(
      t: t,
      useBlur: false, // เบื้องต้นปิดเบลอเพื่อลด GPU; เปิดได้ในเครื่องแรง
      elevated: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          _BadgeIcon(icon: view.icon),
          const SizedBox(width: 10),
          Expanded(
            child: _AnimatedMetricText(
              label: view.label,
              valueStr: view.valueStr,
              unit: view.unit,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: c.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.primary.withOpacity(0.18), width: 1),
      ),
      child: Icon(icon, color: c.primary),
    );
  }
}

/// แสดงตัวเลข + หน่วย พร้อม AnimatedSwitcher (เบามาก ๆ)
class _AnimatedMetricText extends StatelessWidget {
  const _AnimatedMetricText({
    required this.label,
    required this.valueStr,
    required this.unit,
  });

  final String label;
  final String valueStr;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyLarge;
    final title = Theme.of(context).textTheme.titleLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: body),
        const SizedBox(height: 2),
        Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: Text(
                valueStr,
                key: ValueKey(valueStr),
                style: title,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 6),
              Opacity(
              opacity: 0.8,  // Apply opacity here
              child: Text(unit, style: body),),
            ]
          ],
        ),
      ],
    );
  }
}

/// โครงข้อมูลสำหรับ 1 ช่อง
class _MetricView {
  _MetricView({
    required this.id,
    required this.label,
    required this.valueStr,
    required this.unit,
    required this.icon,
  });

  final String id;
  final String label;
  final String valueStr;
  final String unit;
  final IconData icon;
}
