// lib/features/home/home_items.dart
import 'package:flutter/material.dart';
import 'home_layout.dart';                    // HomeTile / HomeLayout
import '../../ui/widgets/feature_card.dart';  // FeatureCard.glass

// ---------- Route names ที่การ์ดจะนำทางไป ----------
const routeWearables = '/wearables';
const routeAiChat    = '/ai_chat';
const routeAiDisease = '/ai_disease';
const routeFood      = '/food';
const routeFit       = '/fit';
const routeMore      = '/more';

// ---------- IDs ของการ์ดบนหน้า Home (อ้างอิงข้ามไฟล์ได้) ----------
class HomeItemIds {
  static const wearable  = 'wearable';
  static const aiChat    = 'ai_chat';
  static const aiDisease = 'ai_disease';
  static const food      = 'food';
  static const fit       = 'fit';
  static const more      = 'more';
}

/// ตัวช่วยสร้างรายการการ์ดบนหน้า Home
/// - `metrics` ใส่ค่าสุดท้ายจากนาฬิกา (เช่น {'heart_rate': 105, ...})
/// - `displayName` ชื่อที่ใช้ทักทาย (ถ้าอยากแสดงบน header ภายนอก)
class HomeItemsBuilder {
  static List<HomeTile> buildTiles({
    required BuildContext context,
    Map<String, num>? metrics,
    String? displayName,
  }) {
    final m = metrics ?? const {};

    String hrText() {
      final v = m['heart_rate'];
      if (v == null) return '—';
      return '${v.toStringAsFixed(0)} bpm';
    }

    return <HomeTile>[
      HomeTile(
        id: HomeItemIds.wearable,
        heightFactor: 1.06, // ให้เด่นขึ้นเล็กน้อยเหมือนดีไซน์ตัวอย่าง
        child: FeatureCard.glass(
          title: 'Wearable',
          subtitle: hrText(),
          icon: Icons.favorite,
          onTap: () => Navigator.of(context).pushNamed(routeWearables),
          padding: const EdgeInsets.all(14),
        ),
      ),
      HomeTile(
        id: HomeItemIds.aiChat,
        child: FeatureCard.glass(
          title: 'AI',
          subtitle: 'Ask anything',
          icon: Icons.chat_bubble_outline,
          onTap: () => Navigator.of(context).pushNamed(routeAiChat),
        ),
      ),
      HomeTile(
        id: HomeItemIds.aiDisease,
        child: FeatureCard.glass(
          title: 'AI วิเคราะห์โรค',
          subtitle: 'Screening',
          icon: Icons.medical_services_outlined,
          onTap: () => Navigator.of(context).pushNamed(routeAiDisease),
        ),
      ),
      HomeTile(
        id: HomeItemIds.food,
        child: FeatureCard.glass(
          title: 'Food',
          subtitle: 'Nutrition',
          icon: Icons.restaurant_outlined,
          onTap: () => Navigator.of(context).pushNamed(routeFood),
        ),
      ),
      HomeTile(
        id: HomeItemIds.fit,
        child: FeatureCard.glass(
          title: 'Fit',
          subtitle: 'Workout',
          icon: Icons.fitness_center_outlined,
          onTap: () => Navigator.of(context).pushNamed(routeFit),
        ),
      ),
      HomeTile(
        id: HomeItemIds.more,
        child: FeatureCard.glass(
          title: 'More',
          subtitle: 'Add feature',
          icon: Icons.add_circle_outline,
          onTap: () => Navigator.of(context).pushNamed(routeMore),
        ),
      ),
    ];
  }
}
