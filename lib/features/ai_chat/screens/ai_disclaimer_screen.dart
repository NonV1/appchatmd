import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

class AiDisclaimerScreen extends StatelessWidget {
  const AiDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Policy'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // หัวข้อ
            Text(
              'โปรดอ่านก่อนใช้งาน',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // กล่องข้อความสไตล์กึ่ง glass (เบา ไม่กินทรัพยากร)
            Container(
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: DefaultTextStyle.merge(
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.9),
                  height: 1.4,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TH
                    Text('• ระบบ AI นี้ไม่ใช่แพทย์จริง ใช้เพื่อให้คำแนะนำทั่วไปเท่านั้น'),
                    SizedBox(height: 6),
                    Text('• ไม่สามารถใช้แทนการวินิจฉัยหรือการรักษาโดยแพทย์'),
                    SizedBox(height: 6),
                    Text('• หากมีอาการรุนแรง โปรดไปโรงพยาบาลทันที'),
                    SizedBox(height: 10),
                    // EN
                    Text('• This AI assistant is not a medical professional.'),
                    SizedBox(height: 6),
                    Text('• For general guidance only; not a diagnosis or treatment.'),
                    SizedBox(height: 6),
                    Text('• In emergencies, go to the nearest hospital immediately.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ข้อความเรื่องข้อมูลสุขภาพ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.privacy_tip_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'เมื่อกด “ยอมรับและเริ่มใช้งาน” คุณยอมรับให้ระบบประมวลผลข้อมูลสุขภาพชั่วคราวเพื่อช่วยวิเคราะห์คำตอบของ AI.',
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),

            // ปุ่มล่าง
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.goNamed(AppRoute.aiChat),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('ยอมรับและเริ่มใช้งาน | I Understand'),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: const Text('ย้อนกลับ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
