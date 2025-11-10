// lib/ui/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../theme/app_theme.dart';
import 'language_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // prefs keys
  static const _kUseBlur = 'pref_use_blur';
  static const _kLowSpec = 'pref_low_spec';
  static const _kReduceMotion = 'pref_reduce_motion';
  static const _kLocale = 'app_locale';

  bool _useBlur = false;
  bool _lowSpec = false;
  bool _reduceMotion = false;
  String _locale = 'en'; // 'en' | 'th'

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _useBlur = p.getBool(_kUseBlur) ?? false;
      _lowSpec = p.getBool(_kLowSpec) ?? false;
      _reduceMotion = p.getBool(_kReduceMotion) ?? false;
      _locale = p.getString(_kLocale) ?? 'en';
      _loading = false;
    });
  }

  Future<void> _saveBool(String key, bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, v);
  }

  Future<void> _saveLocale(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, code);
    setState(() => _locale = code);
  }

  Future<void> _pickLanguage() async {
    final picked = await LanguagePicker.show(context, current: _locale);
    if (picked != null && picked != _locale) {
      await _saveLocale(picked);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language set to ${picked.toUpperCase()}')),
      );
      // หมายเหตุ: ตอนนี้ยังไม่ได้ผูกกับระบบ i18n (ARB)
      // ต่อไปให้ main.dart อ่าน _kLocale แล้วตั้ง locale ที่ MaterialApp
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --------- Appearance / Performance ----------
                Text('Appearance & Performance',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Glass.panel(
                  t: t,
                  useBlur: _useBlur, // สอดคล้องกับ toggle
                  elevated: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: const Text('Glass blur effects'),
                        subtitle: const Text('Frosted panels (may increase GPU usage)'),
                        value: _useBlur,
                        onChanged: (v) async {
                          setState(() => _useBlur = v);
                          await _saveBool(_kUseBlur, v);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        title: const Text('Low-spec mode'),
                        subtitle: const Text('Reduce gradients, shadows, and paints'),
                        value: _lowSpec,
                        onChanged: (v) async {
                          setState(() => _lowSpec = v);
                          await _saveBool(_kLowSpec, v);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        title: const Text('Reduce motion'),
                        subtitle: const Text('Limit page and number animations'),
                        value: _reduceMotion,
                        onChanged: (v) async {
                          setState(() => _reduceMotion = v);
                          await _saveBool(_kReduceMotion, v);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --------- Language ----------
                Text('Language', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Glass.panel(
                  t: t,
                  useBlur: _useBlur,
                  elevated: true,
                  child: ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('App language'),
                    subtitle: Text(_locale == 'th' ? 'ไทย (TH)' : 'English (EN)'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _pickLanguage,
                  ),
                ),

                const SizedBox(height: 16),

                // --------- Wearables / Permissions (placeholder) ----------
                Text('Wearables', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Glass.panel(
                  t: t,
                  useBlur: _useBlur,
                  elevated: true,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.watch_rounded),
                        title: const Text('Manage permissions'),
                        subtitle: const Text('Health Connect / HealthKit'),
                        trailing: const Icon(Icons.open_in_new_rounded),
                        onTap: () {
                          // TODO: เปิดหน้าตั้งค่า Health Connect หรือ internal screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coming soon')),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --------- Account ----------
                Text('Account', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Glass.panel(
                  t: t,
                  useBlur: _useBlur,
                  elevated: true,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_rounded),
                        title: const Text('Profile'),
                        subtitle: const Text('View or edit medical profile'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          // TODO: ไปหน้าโปรไฟล์ละเอียด / กรอกโรคที่เป็น
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coming soon')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                        title: const Text('Log out'),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
