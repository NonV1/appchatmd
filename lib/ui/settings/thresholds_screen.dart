// lib/ui/settings/thresholds_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';

class ThresholdsScreen extends StatefulWidget {
  const ThresholdsScreen({super.key});

  @override
  State<ThresholdsScreen> createState() => _ThresholdsScreenState();
}

class _ThresholdsScreenState extends State<ThresholdsScreen> {
  // keys
  static const _kHrRestMax = 'th_hr_rest_max';
  static const _kHrExerciseMax = 'th_hr_exercise_max';
  static const _kSpo2Min = 'th_spo2_min';
  static const _kSleepMinHours = 'th_sleep_min_hours';
  static const _kGlucoseMax = 'th_glucose_max';

  // defaults
  double _hrRestMax = 110;
  double _hrExMax = 160;
  double _spo2Min = 92;
  double _sleepMinHours = 6;
  double _glucoseMax = 180;

  bool _loading = true;
  bool _useBlur = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _hrRestMax = p.getDouble(_kHrRestMax) ?? 110;
      _hrExMax = p.getDouble(_kHrExerciseMax) ?? 160;
      _spo2Min = p.getDouble(_kSpo2Min) ?? 92;
      _sleepMinHours = p.getDouble(_kSleepMinHours) ?? 6;
      _glucoseMax = p.getDouble(_kGlucoseMax) ?? 180;
      _useBlur = p.getBool('pref_use_blur') ?? false;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kHrRestMax, _hrRestMax);
    await p.setDouble(_kHrExerciseMax, _hrExMax);
    await p.setDouble(_kSpo2Min, _spo2Min);
    await p.setDouble(_kSleepMinHours, _sleepMinHours);
    await p.setDouble(_kGlucoseMax, _glucoseMax);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved thresholds')),
    );
  }

  Future<void> _reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kHrRestMax);
    await p.remove(_kHrExerciseMax);
    await p.remove(_kSpo2Min);
    await p.remove(_kSleepMinHours);
    await p.remove(_kGlucoseMax);
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Personal thresholds')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Heart rate', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Glass.panel(
                  t: t, useBlur: _useBlur, elevated: true,
                  child: Column(
                    children: [
                      _sliderTile(
                        title: 'Max (resting)',
                        value: _hrRestMax,
                        min: 60, max: 140, divisions: 80,
                        unit: 'bpm',
                        onChanged: (v) => setState(() => _hrRestMax = v),
                      ),
                      const Divider(height: 1),
                      _sliderTile(
                        title: 'Max (exercise)',
                        value: _hrExMax,
                        min: 100, max: 200, divisions: 100,
                        unit: 'bpm',
                        onChanged: (v) => setState(() => _hrExMax = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text('Oxygen & Sleep', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Glass.panel(
                  t: t, useBlur: _useBlur, elevated: true,
                  child: Column(
                    children: [
                      _sliderTile(
                        title: 'SpO₂ minimum',
                        value: _spo2Min,
                        min: 80, max: 100, divisions: 20,
                        unit: '%',
                        onChanged: (v) => setState(() => _spo2Min = v),
                      ),
                      const Divider(height: 1),
                      _sliderTile(
                        title: 'Sleep minimum',
                        value: _sleepMinHours,
                        min: 3, max: 10, divisions: 7,
                        unit: 'h',
                        onChanged: (v) => setState(() => _sleepMinHours = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text('Glucose', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Glass.panel(
                  t: t, useBlur: _useBlur, elevated: true,
                  child: _sliderTile(
                    title: 'Max glucose',
                    value: _glucoseMax,
                    min: 120, max: 260, divisions: 140,
                    unit: 'mg/dL',
                    onChanged: (v) => setState(() => _glucoseMax = v),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _sliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      title: Text('$title  •  ${value.toStringAsFixed(0)} $unit'),
      subtitle: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: '${value.toStringAsFixed(0)} $unit',
        onChanged: onChanged,
      ),
    );
  }
}
