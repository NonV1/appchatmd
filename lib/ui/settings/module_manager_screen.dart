// lib/ui/settings/module_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';

class ModuleManagerScreen extends StatefulWidget {
  const ModuleManagerScreen({super.key});

  @override
  State<ModuleManagerScreen> createState() => _ModuleManagerScreenState();
}

class _ModuleManagerScreenState extends State<ModuleManagerScreen> {
  final _keys = const {
    'wearables': 'module_wearables',
    'ai_chat': 'module_ai_chat',
    'ai_disease': 'module_ai_disease',
    'food': 'module_food',
    'fit': 'module_fit',
    'more': 'module_more',
  };

  // ค่าดีฟอลต์ (เปิดส่วนหลักไว้ก่อน)
  final Map<String, bool> _defaults = const {
    'wearables': true,
    'ai_chat': true,
    'ai_disease': false,
    'food': false,
    'fit': false,
    'more': true,
  };

  final Map<String, bool> _enabled = {};
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
      for (final entry in _defaults.entries) {
        final key = _keys[entry.key]!;
        _enabled[entry.key] = p.getBool(key) ?? entry.value;
      }
      _useBlur = p.getBool('pref_use_blur') ?? false;
      _loading = false;
    });
  }

  Future<void> _toggle(String id, bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keys[id]!, v);
    setState(() => _enabled[id] = v);
  }

  Future<void> _resetDefaults() async {
    final p = await SharedPreferences.getInstance();
    for (final e in _defaults.entries) {
      await p.setBool(_keys[e.key]!, e.value);
      _enabled[e.key] = e.value;
    }
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modules reset to defaults')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Modules')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Enable / Disable features',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),

                // กล่องรวมสวิตช์
                Glass.panel(
                  t: t,
                  useBlur: _useBlur,
                  elevated: true,
                  child: Column(
                    children: [
                      _tile('Wearables', 'Steps, HR, Sleep, SpO₂ etc.',
                          'wearables'),
                      const Divider(height: 1),
                      _tile('AI Chat', 'General medical QA (disclaimer shown)',
                          'ai_chat'),
                      const Divider(height: 1),
                      _tile('AI Disease', 'Symptom checker & plan suggestion',
                          'ai_disease'),
                      const Divider(height: 1),
                      _tile('Food', 'Log meals & nutrition insights', 'food'),
                      const Divider(height: 1),
                      _tile('Fit', 'Workouts & activity trends', 'fit'),
                      const Divider(height: 1),
                      _tile('More', 'Quick actions & extra tools', 'more'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                FilledButton.tonalIcon(
                  icon: const Icon(Icons.restart_alt_rounded),
                  onPressed: _resetDefaults,
                  label: const Text('Reset defaults'),
                ),
              ],
            ),
    );
  }

  Widget _tile(String title, String subtitle, String id) {
    return SwitchListTile.adaptive(
      title: Text(title),
      subtitle: Text(subtitle),
      value: _enabled[id] ?? false,
      onChanged: (v) => _toggle(id, v),
    );
  }
}
