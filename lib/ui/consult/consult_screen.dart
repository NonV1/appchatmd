import 'package:flutter/material.dart';
import '../../features/auth/widgets/glass_card.dart';

/// หน้าปรึกษาแพทย์ (placeholder)
/// - โชว์ตัวเลือกปรึกษาออนไลน์/ออฟไลน์
/// - มี quick actions และกล่องข้อความสั้น ๆ
class ConsultScreen extends StatelessWidget {
  const ConsultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Consult')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // แบนเนอร์คำแนะนำสั้น ๆ
            GlassCard(
              blurSigma: 10,
              elevation: 6,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ข้อมูลจากแอปนี้เป็นเพียงข้อมูลประกอบการตัดสินใจ ไม่ใช่คำวินิจฉัยทางการแพทย์ หากอาการรุนแรงให้ไปโรงพยาบาลทันที',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick actions
            GlassCard(
              blurSigma: 10,
              elevation: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เริ่มปรึกษาอย่างรวดเร็ว',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            // TODO: ไปยัง video call provider
                          },
                          icon: const Icon(Icons.videocam_outlined),
                          label: const Text('วิดีโอคอล'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: ไปยังจองคิวคลินิก
                          },
                          icon: const Icon(Icons.local_hospital_outlined),
                          label: const Text('จองคิวคลินิก'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ฟอร์มบอกอาการแบบย่อ
            GlassCard(
              blurSigma: 10,
              elevation: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เล่าอาการเบื้องต้น',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const TextField(
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText:
                          'เช่น ไข้ ปวดหัว เจ็บคอ หายใจไม่สะดวก เริ่มมีอาการตั้งแต่เมื่อไหร่...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        // TODO: ส่งรายละเอียดไป backend/queue
                      },
                      child: const Text('ส่งรายละเอียด'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
