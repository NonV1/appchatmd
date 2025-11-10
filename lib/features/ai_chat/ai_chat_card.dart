import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../ui/widgets/feature_card.dart'; // การ์ดแบบโมดูลาร์ที่เราใช้บน Home

class AiChatCard extends StatelessWidget {
  const AiChatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      title: 'AI Doctor',
      subtitle: 'ถาม-ตอบสุขภาพทั่วไป',
      leading: const Icon(Icons.medical_information_outlined, size: 28),
      onTap: () {
        // ไปหน้าแจ้งเตือนนโยบายทุกครั้ง ก่อนเข้าห้องแชต
        context.pushNamed(AppRoute.aiDisclaimer);
      },
    );
  }
}
