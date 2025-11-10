import 'package:flutter/material.dart';
import '../../features/auth/widgets/glass_card.dart';
import '../../core/data/user_repo.dart';
import '../../core/models/user_profile.dart';
import '../../core/api/http_client.dart';
import '../../core/user/session.dart';
import '../../core/api/http_client.dart';
import '../../core/user/session.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key, this.onNext});

  final VoidCallback? onNext;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _sex = 'unspecified';
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _allergies = TextEditingController();

  bool _saving = false;
  late final UserRepo _repo = UserRepo(
    api: HttpClient.I.rawClient,
    session: Session.I,
  );

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _allergies.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final profile = UserProfile(
        displayName: _name.text.trim(),
        gender: _sex,
        // UserProfile stores birthDate (ISO yyyy-MM-dd). If the user entered
        // an age, convert it to an approximate birthDate using today's date.
        birthDate: () {
          final a = int.tryParse(_age.text.trim());
          if (a == null) return null;
          final now = DateTime.now();
          // approximate by subtracting years; keep month/day the same as today
          final bd = DateTime(now.year - a, now.month, now.day);
          return bd.toIso8601String().split('T').first;
        }(),
        heightCm: double.tryParse(_height.text.trim()),
        weightKg: double.tryParse(_weight.text.trim()),
        allergies: _parseAllergies(),
      );
      await _repo.saveProfile(profile);
      if (mounted) {
        widget.onNext?.call();
        // ถ้าไม่ส่ง onNext มา จะ pop กลับ
        if (widget.onNext == null) Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _parseAllergies() {
    final text = _allergies.text;
    if (text.trim().isEmpty) return const [];
    return text
        .split(RegExp(r'[,;\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('ข้อมูลผู้ใช้')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: GlassCard(
                blurSigma: 10,
                elevation: 6,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text('กรอกข้อมูลพื้นฐาน', style: t.textTheme.titleLarge),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อ-นามสกุล',
                          hintText: 'เช่น Natthawat Phummarin',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue: _sex,
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('ชาย')),
                          DropdownMenuItem(value: 'female', child: Text('หญิง')),
                          DropdownMenuItem(value: 'unspecified', child: Text('ไม่ระบุ')),
                        ],
                        onChanged: (v) => setState(() => _sex = v ?? 'unspecified'),
                        decoration: const InputDecoration(labelText: 'เพศ'),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _age,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'อายุ (ปี)'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                final n = int.tryParse(v);
                                if (n == null || n < 0 || n > 120) return 'อายุไม่ถูกต้อง';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _height,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'ส่วนสูง (ซม.)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _weight,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'น้ำหนัก (กก.)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _allergies,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'แพ้ยา/หมายเหตุ (ถ้ามี)',
                          hintText: 'เช่น แพ้ Penicillin',
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                              child: const Text('ย้อนกลับ'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _saving ? null : _submit,
                              child: _saving
                                  ? const SizedBox(
                                      height: 20, width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('ถัดไป'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// helper removed: replaced by _parseAllergies() within the widget
