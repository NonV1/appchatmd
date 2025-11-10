import 'package:flutter/material.dart';
import '../../features/auth/widgets/glass_card.dart';
import '../../core/data/user_repo.dart';
import '../../core/api/http_client.dart';
import '../../core/user/session.dart';
import '../../core/api/http_client.dart';
import '../../core/user/session.dart';

/// รายการตัวอย่าง (แก้/เพิ่มได้ตามโปรเจกต์จริง)
const _conditions = <String>[
  'diabetes',
  'hypertension',
  'asthma',
  'dyslipidemia',
  'sleep_apnea',
  'arrhythmia',
  'ckd',
  'cad',
];

class ConditionsPickerScreen extends StatefulWidget {
  const ConditionsPickerScreen({super.key, this.onNext});

  final VoidCallback? onNext;

  @override
  State<ConditionsPickerScreen> createState() => _ConditionsPickerScreenState();
}

class _ConditionsPickerScreenState extends State<ConditionsPickerScreen> {
  late final UserRepo _repo = UserRepo(
    api: HttpClient.I.rawClient,
    session: Session.I,
  );
  final Set<String> _selected = <String>{};
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _repo.saveConditions(_selected.toList(growable: false));
      if (mounted) {
        widget.onNext?.call();
        if (widget.onNext == null) Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('เงื่อนไขสุขภาพของคุณ')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: GlassCard(
                blurSigma: 10,
                elevation: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('เลือกโรค/ภาวะที่คุณมี',
                        style: t.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _conditions.map((c) {
                        final selected = _selected.contains(c);
                        return FilterChip(
                          selected: selected,
                          label: Text(_labelOf(c)),
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _selected.add(c);
                              } else {
                                _selected.remove(c);
                              }
                            });
                          },
                        );
                      }).toList(),
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
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    height: 20, width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('เสร็จสิ้น'),
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
    );
  }

  String _labelOf(String key) {
    switch (key) {
      case 'diabetes': return 'เบาหวาน';
      case 'hypertension': return 'ความดันโลหิตสูง';
      case 'asthma': return 'หอบหืด';
      case 'dyslipidemia': return 'ไขมันในเลือดผิดปกติ';
      case 'sleep_apnea': return 'หยุดหายใจขณะหลับ';
      case 'arrhythmia': return 'หัวใจเต้นผิดจังหวะ';
      case 'ckd': return 'โรคไตเรื้อรัง';
      case 'cad': return 'โรคหลอดเลือดหัวใจ';
      default: return key;
    }
  }
}
