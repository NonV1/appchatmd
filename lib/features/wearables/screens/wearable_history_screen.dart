import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

import '../../../core/data/health_repo.dart';
import '../../../utils/format.dart' as fmt;
import '../../../theme/app_theme.dart';

class WearableHistoryScreen extends StatefulWidget {
  const WearableHistoryScreen({super.key});

  @override
  State<WearableHistoryScreen> createState() => _WearableHistoryScreenState();
}

class _WearableHistoryScreenState extends State<WearableHistoryScreen> {
  final _repo = HealthRepo();
  DateTime _selected = DateTime.now();
  Map<String, num> _totals = const {};
  List<double> _steps = const [];
  List<double> _energy = const [];
  List<double> _hrAvg = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final totals = await _repo.fetchDayTotals(_selected);
    final steps = await _repo.fetchStepsByHour(_selected);
    final energy = await _repo.fetchEnergyByHour(_selected);
    final hr = await _repo.fetchHrAvgByHour(_selected);
    if (!mounted) return;
    setState(() {
      _totals = totals;
      _steps = steps;
      _energy = energy;
      _hrAvg = hr;
      _loading = false;
    });
  }

  void _pickDay(DateTime d) {
    setState(() => _selected = d);
    _load();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Wearables • History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: [
                // Date selector (30 days)
                GlassContainer(
                  blur: 8,
                  borderRadius: t.radius,
                  color: cs.surface.withOpacity(.6),
                  border: Border.all(color: cs.onSurface.withOpacity(.1)),
                  shadowStrength: 6,
                  child: SizedBox(
                    height: 72,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      children: _lastDays(30).map((d) {
                        final selected = _selected.year == d.year &&
                            _selected.month == d.month &&
                            _selected.day == d.day;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ChoiceChip(
                            selected: selected,
                            label: Text('${d.month}/${d.day}'),
                            onSelected: (_) => _pickDay(d),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Totals
                GlassContainer(
                  blur: 8,
                  borderRadius: t.radius,
                  color: cs.surface.withOpacity(.6),
                  border: Border.all(color: cs.onSurface.withOpacity(.1)),
                  shadowStrength: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _totalTile('Steps', fmt.fmtInt(_totals['steps'])),
                        _totalTile('Energy', fmt.fmtKcal(_totals['active_energy_kcal'])),
                        _totalTile('HR avg', _totals['heart_rate'] == null
                            ? '—'
                            : '${_totals['heart_rate']!.toStringAsFixed(0)} bpm'),
                        _totalTile('Sleep', _totals['sleep_sec'] == null
                            ? '—'
                            : fmt.fmtHCompact(Duration(seconds: _totals['sleep_sec']!.toInt()))),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                _section(context, 'Steps (per hour)', _steps, cs.primary),
                const SizedBox(height: 12),
                _section(context, 'Active energy (kcal/h)', _energy, Colors.pinkAccent),
                const SizedBox(height: 12),
                _lineSection(context, 'Heart rate (avg bpm/h)', _hrAvg, Colors.redAccent),
              ],
            ),
    );
  }

  Widget _totalTile(String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<double> data, Color color) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              for (int i = 0; i < (data.isEmpty ? 24 : data.length); i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: data.isEmpty ? 0 : data[i],
                    color: color.withOpacity(.9),
                    width: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ]),
            ],
          )),
        ),
      ],
    );
  }

  Widget _lineSection(BuildContext context, String title, List<double> data, Color color) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: LineChart(LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                color: color,
                isCurved: true,
                barWidth: 2,
                spots: [
                  for (int i = 0; i < (data.isEmpty ? 0 : data.length); i++)
                    FlSpot(i.toDouble(), data[i]),
                ],
              ),
            ],
          )),
        ),
      ],
    );
  }
}

