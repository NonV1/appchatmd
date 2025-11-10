// lib/features/wearables/screens/unified_wearable_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

import '../../../core/data/health_repo.dart';
import '../../../core/models/wearable_metrics.dart';

import '../../../theme/app_theme.dart';
import '../widgets/activity_rings.dart';

class UnifiedWearableScreen extends StatefulWidget {
  const UnifiedWearableScreen({super.key});
  
  @override
  State<UnifiedWearableScreen> createState() => _UnifiedWearableScreenState();
}

class _UnifiedWearableScreenState extends State<UnifiedWearableScreen> {
  final _health = HealthRepo();
  
  // Selected date and metrics
  DateTime _selectedDate = DateTime.now();
  Map<String, num> _metrics = const {};
  List<double> _hrSeries = const [];
  List<double> _stepsSeries = const [];
  List<double> _energySeries = const [];
  
  @override
  void initState() {
    super.initState();
    _loadDataForDate(_selectedDate);
  }

  Future<void> _loadDataForDate(DateTime date) async {
    try {
      // Load metrics for selected date
      final metrics = await _health.fetchDayTotals(date);
      final steps = await _health.fetchStepsByHour(date);
      final energy = await _health.fetchEnergyByHour(date);
      final hr = await _health.fetchHrAvgByHour(date);
      
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _stepsSeries = steps;
          _energySeries = energy;
          _hrSeries = hr;
        });
      }
    } catch (e) {
      print('Error loading data for ${date}: $e');
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
    _loadDataForDate(date);
  }

  Iterable<DateTime> _lastDays(int n) sync* {
    final now = DateTime.now();
    for (int i = 0; i < n; i++) {
      yield DateTime(now.year, now.month, now.day - i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTheme.tokensOf(context);
    final textTheme = Theme.of(context).textTheme;
    
    const padding = EdgeInsets.all(16);

    return Scaffold(
      appBar: AppBar(title: const Text('Health Metrics')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector
            Padding(
              padding: padding,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final date in _lastDays(7))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _DateChip(
                          date: date,
                          selected: date.day == _selectedDate.day,
                          onTap: () => _onDateSelected(date),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Metrics rings for selected date
            Padding(
              padding: padding,
              child: GlassContainer(
                borderRadius: t.radius,
                blur: 10,
                color: cs.surface.withOpacity(0.7),
                border: Border.all(color: t.glassBorder),
                child: Padding(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDate.day == DateTime.now().day 
                          ? 'Today\'s Progress'
                          : '${_selectedDate.day}/${_selectedDate.month} Progress',
                        style: textTheme.titleMedium
                      ),
                      const SizedBox(height: 16),
                      _buildMetricRings(context),
                    ],
                  ),
                ),
              ),
            ),

            // Historical graphs
            Padding(
              padding: padding,
              child: GlassContainer(
                borderRadius: t.radius,
                blur: 10,
                color: cs.surface.withOpacity(0.7),
                border: Border.all(color: t.glassBorder),
                child: Padding(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month} Activity',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildHistoryGraphs(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRings(BuildContext context) {
    final rings = <ActivityRingSpec>[];
    
    // Steps ring (outermost)
    if (_metrics.containsKey(MetricIds.steps)) {
      rings.add(ActivityRingSpec(
        value: _metrics[MetricIds.steps]!.toDouble(),
        goal: 10000,
        color: Colors.blue,
      ));
    }
    
    // Active calories ring (middle)
    if (_metrics.containsKey(MetricIds.activeEnergyKcal)) {
      rings.add(ActivityRingSpec(
        value: _metrics[MetricIds.activeEnergyKcal]!.toDouble(),
        goal: 400,
        color: Colors.orange,
      ));
    }
    
    // Heart rate ring (innermost)
    if (_metrics.containsKey(MetricIds.heartRate)) {
      rings.add(ActivityRingSpec(
        value: _metrics[MetricIds.heartRate]!.toDouble(),
        goal: 220,
        color: Colors.red,
      ));
    }

    return Column(
      children: [
        Center(
          child: ActivityRings(
            rings: rings,
            size: 200,
            stroke: 20,
          ),
        ),
        const SizedBox(height: 24),
        // Metrics legend with icons
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _MetricIndicator(
              icon: Icons.directions_walk,
              label: 'Steps',
              value: _metrics[MetricIds.steps]?.toInt() ?? 0,
              goal: 10000,
              color: Colors.blue,
            ),
            _MetricIndicator(
              icon: Icons.local_fire_department,
              label: 'Calories',
              value: _metrics[MetricIds.activeEnergyKcal]?.toInt() ?? 0,
              goal: 400,
              color: Colors.orange,
            ),
            _MetricIndicator(
              icon: Icons.favorite,
              label: 'Heart Rate',
              value: _metrics[MetricIds.heartRate]?.toInt() ?? 0,
              goal: 220,
              color: Colors.red,
            ),
          ],
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildHistoryGraphs(BuildContext context) {
    return Column(
      children: [
        if (_stepsSeries.isNotEmpty)
          _HistoryGraph(
            data: _stepsSeries,
            label: 'Steps',
            color: Colors.blue,
          ),
        const SizedBox(height: 16),
        if (_energySeries.isNotEmpty)
          _HistoryGraph(
            data: _energySeries,
            label: 'Active Calories',
            color: Colors.orange,
          ),
        const SizedBox(height: 16),
        if (_hrSeries.isNotEmpty)
          _HistoryGraph(
            data: _hrSeries,
            label: 'Heart Rate',
            color: Colors.red,
          ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected ? cs.primaryContainer : cs.surface,
      borderRadius: t.radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: t.radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Column(
            children: [
              Text(
                '${date.day}/${date.month}',
                style: textTheme.labelMedium?.copyWith(
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int goal;
  final Color color;

  const _MetricIndicator({
    required this.icon,
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ).animate(
            onPlay: (controller) => controller.repeat(),
          ).scaleXY(
            begin: 0.9,
            end: 1.1,
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.toString(),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryGraph extends StatelessWidget {
  final List<double> data;
  final String label;
  final Color color;

  const _HistoryGraph({
    required this.data,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconForLabel(label),
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < data.length; i++)
                        FlSpot(i.toDouble(), data[i]),
                    ],
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'steps':
        return Icons.directions_walk;
      case 'active calories':
        return Icons.local_fire_department;
      case 'heart rate':
        return Icons.favorite;
      default:
        return Icons.show_chart;
    }
  }
}