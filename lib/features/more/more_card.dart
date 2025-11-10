import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../ui/widgets/feature_card.dart';
import 'screens/more_screen.dart';

class MoreCard extends StatelessWidget {
  const MoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      title: 'More',
      subtitle: 'ฟีเจอร์อื่น ๆ / จัดการโมดูล',
      leading: const Icon(Icons.apps_outlined, size: 28),
      onTap: () {
        // ถ้ามี GoRoute ชื่อ more ให้ไปตามชื่อ route
        try {
          context.pushNamed(AppRoute.more);
        } catch (_) {
          // ถ้ายังไม่ได้ประกาศ route ชื่อ more ให้เปิดหน้าตรง ๆ
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MoreScreen()),
          );
        }
      },
    );
  }
}
