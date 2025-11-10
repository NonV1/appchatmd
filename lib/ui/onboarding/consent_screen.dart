import 'package:flutter/material.dart';
import '../../features/auth/widgets/glass_card.dart';

/// หน้า Consent & Policy ช่วง Onboarding
/// - ผู้ใช้ต้องกดยอมรับก่อนใช้งาน (ควรเซฟสถานะลง storage)
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, this.onAccepted});

  /// callback เมื่อผู้ใช้กดยอมรับ (ถ้าไม่ส่งมา จะ pop กลับเอง)
  final VoidCallback? onAccepted;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ข้อตกลงและนโยบาย')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassCard(
                  blurSigma: 10,
                  elevation: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ข้อกำหนดการใช้งาน',
                          style: t.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _bullet(
                        context,
                        'แอปนี้ไม่ใช่แพทย์ และไม่ทดแทนการวินิจฉัยจากผู้เชี่ยวชาญ',
                      ),
                      _bullet(
                        context,
                        'ข้อมูล AI/แชต เป็นคำแนะนำทั่วไป โปรดใช้วิจารณญาณ',
                      ),
                      _bullet(
                        context,
                        'การแจ้งเตือนสุขภาพเป็นข้อมูลจากอุปกรณ์สวมใส่ที่คุณอนุญาต',
                      ),
                      _bullet(
                        context,
                        'โปรดอ่านนโยบายความเป็นส่วนตัวฉบับเต็มก่อนใช้งาน',
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          // TODO: เปิดหน้า/ลิงก์ นโยบายความเป็นส่วนตัว
                        },
                        icon: const Icon(Icons.privacy_tip_outlined),
                        label: const Text('อ่านนโยบายความเป็นส่วนตัว'),
                      ),
                      const Divider(height: 24),
                      CheckboxListTile(
                        value: _checked,
                        onChanged: (v) => setState(() => _checked = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                            'ฉันได้อ่านและยอมรับข้อตกลงและนโยบายทั้งหมด'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              child: const Text('ยกเลิก'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _checked
                                  ? () async {
                                      // TODO: บันทึก consent = true ลง storage/profiles
                                      if (widget.onAccepted != null) {
                                        widget.onAccepted!();
                                      } else {
                                        Navigator.of(context).pop(true);
                                      }
                                    }
                                  : null,
                              child: const Text('ยอมรับและดำเนินการต่อ'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // เกร็ดสำคัญ (ย้ำอีกครั้ง)
                GlassCard(
                  blurSigma: 10,
                  elevation: 6,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_outlined,
                          color: t.colorScheme.secondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'หากมีอาการหนัก เช่น เจ็บหน้าอกรุนแรง หายใจติดขัด หมดสติ ให้รีบไปโรงพยาบาลทันที',
                          style: t.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    final c = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text, style: c)),
        ],
      ),
    );
  }
}
