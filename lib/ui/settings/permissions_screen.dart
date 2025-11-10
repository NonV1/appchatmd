// lib/ui/settings/permissions_screen.dart
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Health _health = Health();
  bool _loading = false;
  bool _useBlur = false;

  String _status = '—';
  WearablePreview? _preview;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _configure();
  }

  Future<void> _initPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _useBlur = p.getBool('pref_use_blur') ?? false);
  }

  Future<void> _configure() async {
    try {
      await _health.configure();
    } catch (_) {}
  }

  List<HealthDataType> get _types => const [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.NUTRITION,
        HealthDataType.BODY_FAT_PERCENTAGE,
        HealthDataType.BLOOD_GLUCOSE,
        HealthDataType.APPLE_MOVE_TIME, // ใช้แทน exercise summary ใน plugin
      ];

  List<HealthDataAccess> get _perms =>
      List.filled(_types.length, HealthDataAccess.READ);

  Future<void> _checkStatus() async {
    setState(() {
      _loading = true;
      _status = 'Checking…';
    });
    try {
      if (Platform.isAndroid) {
        final avail = await _health.isHealthConnectAvailable();
        _status = 'Health Connect available: $avail';
      } else if (Platform.isIOS) {
        _status = 'Using Apple HealthKit';
      } else {
        _status = 'Unsupported platform';
      }
    } catch (e) {
      _status = 'Error: $e';
    }
    setState(() => _loading = false);
  }

  Future<void> _request() async {
    setState(() {
      _loading = true;
      _status = 'Requesting permissions…';
    });
    try {
      final ok = await _health.requestAuthorization(_types, permissions: _perms);
      _status = ok ? 'Permissions granted' : 'Permissions denied';
    } catch (e) {
      _status = 'Error: $e';
    }
    setState(() => _loading = false);
  }

  Future<void> _refreshSample() async {
    setState(() {
      _loading = true;
      _status = 'Refreshing preview…';
    });
    WearablePreview? prev;
    try {
      final now = DateTime.now();
      final today0 = DateTime(now.year, now.month, now.day);

      final steps = await _health.getTotalStepsInInterval(today0, now) ?? 0;

      final hrRaw = await _health.getHealthDataFromTypes(
        startTime: today0,
        endTime: now,
        types: const [HealthDataType.HEART_RATE],
      );
      double? hr;
      if (hrRaw.isNotEmpty) {
        final v = hrRaw.last.value;
        if (v is NumericHealthValue) {
          hr = v.numericValue.toDouble();
        }
      }

      final spo2Raw = await _health.getHealthDataFromTypes(
        startTime: now.subtract(const Duration(hours: 6)),
        endTime: now,
        types: const [HealthDataType.BLOOD_OXYGEN],
      );
      double? spo2;
      if (spo2Raw.isNotEmpty) {
        final v = spo2Raw.last.value;
        if (v is NumericHealthValue) {
          spo2 = v.numericValue.toDouble();
        }
      }

      prev = WearablePreview(steps: steps, hr: hr, spo2: spo2);
      _status = 'Preview updated';
    } catch (e) {
      _status = 'Error: $e';
    }
    setState(() {
      _preview = prev;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Health data permissions',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),

          // Panel: action buttons
          Glass.panel(
            t: t,
            useBlur: _useBlur,
            elevated: true,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Status'),
                  subtitle: Text(_status),
                ),
                const Divider(height: 1),
                OverflowBar(
                  alignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _checkStatus,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Check'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _request,
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Request'),
                    ),
                    FilledButton.icon(
                      onPressed: _loading ? null : _refreshSample,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh sample'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Panel: preview data
          Glass.panel(
            t: t,
            useBlur: _useBlur,
            elevated: true,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.donut_small_rounded),
                  title: const Text('Sample metrics (today)'),
                  subtitle: Text(
                    _preview == null
                        ? '—'
                        : 'Steps: ${_preview!.steps} • HR: ${_preview!.hr?.toStringAsFixed(0) ?? '—'} bpm • SpO₂: ${_preview!.spo2?.toStringAsFixed(0) ?? '—'}%',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Panel: notes
          Glass.panel(
            t: t,
            useBlur: _useBlur,
            elevated: false,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Notes:\n'
                '• On Android, make sure Health Connect app is installed and enable permissions there.\n'
                '• On iOS, ensure Apple Health permissions are granted.\n'
                '• Some watches may not provide all data types; unavailable metrics simply won’t appear.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WearablePreview {
  final int steps;
  final double? hr;
  final double? spo2;
  WearablePreview({required this.steps, this.hr, this.spo2});
}
