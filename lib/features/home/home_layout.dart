// lib/features/home/home_layout.dart
import 'package:flutter/material.dart';

/// โมเดลของการ์ดบนหน้า Home — แก้/เพิ่มเฉพาะที่นี่ ไม่ต้องยุ่งกับหน้า Home
class HomeTile {
  const HomeTile({
    required this.id,
    required this.child,
    this.heightFactor = 1.0, // ปรับ “ความสูงในการ์ด” แบบซอฟท์ ๆ
  });

  final String id;
  final Widget child;

  /// 1.0 = ปกติ, >1.0 = สูงขึ้นเล็กน้อย (เช่น 1.06 ให้เด่นกว่า)
  final double heightFactor;
}

/// ตัววางเลย์เอาต์ 2 คอลัมน์ (โปร่ง/ลื่น ไม่มีแพ็กเกจภายนอก)
/// - ใช้กับการ์ดทุกชนิด (FeatureCard.glass, WearableCard ฯลฯ)
/// - อยากเพิ่ม/ย้ายการ์ด => จัดรายการ [tiles] ใหม่เท่านั้น
class HomeLayout extends StatelessWidget {
  const HomeLayout({
    super.key,
    required this.tiles,
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 24),
    this.mainAxisSpacing = 14,
    this.crossAxisSpacing = 14,
    this.childAspectRatio = 0.92, // สัดส่วนการ์ดให้ดูสูงโปร่งตามแรงบันดาลใจ
  });

  final List<HomeTile> tiles;
  final EdgeInsets padding;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final t = tiles[index];

            // หมายเหตุ: Flutter core ยังไม่รองรับ “ไทล์สูงไม่เท่ากัน” แบบจริงจัง
            // โดยไม่ใช้แพ็กเกจภายนอก; ตรงนี้จึงทำเป็น “soft height”
            // คือใส่ Padding/Align ให้การ์ดบางใบดูสูงและเด่นขึ้น
            final child = t.heightFactor == 1.0
                ? t.child
                : Align(
                    alignment: Alignment.topCenter,
                    child: FractionallySizedBox(
                      heightFactor: t.heightFactor.clamp(0.9, 1.2),
                      child: t.child,
                    ),
                  );

            return child;
          },
          childCount: tiles.length,
        ),
      ),
    );
  }
}
