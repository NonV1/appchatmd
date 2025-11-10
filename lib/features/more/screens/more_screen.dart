import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _safeGoNamed(BuildContext context, String routeName) {
    try {
      context.pushNamed(routeName);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ยังไม่ได้ตั้งค่าเส้นทาง: $routeName')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final sections = <_MoreSection>[
      _MoreSection(
        title: 'Health & AI',
        items: [
          _MoreItem(
            icon: Icons.health_and_safety_outlined,
            title: 'AI Disease Analyzer',
            subtitle: 'วิเคราะห์ความเสี่ยงเบื้องต้น (ไม่ใช่การวินิจฉัย)',
            onTap: () => _safeGoNamed(context, AppRoute.aiDisease),
          ),
          _MoreItem(
            icon: Icons.chat_bubble_outline,
            title: 'AI Doctor (Chat)',
            subtitle: 'ถาม-ตอบสุขภาพทั่วไป',
            onTap: () => _safeGoNamed(context, AppRoute.aiDisclaimer),
          ),
        ],
      ),
      _MoreSection(
        title: 'Lifestyle',
        items: [
          _MoreItem(
            icon: Icons.restaurant_outlined,
            title: 'Food & Nutrition',
            subtitle: 'บันทึกและติดตามโภชนาการ',
            onTap: () => _safeGoNamed(context, AppRoute.food),
          ),
          _MoreItem(
            icon: Icons.fitness_center_outlined,
            title: 'Fitness',
            subtitle: 'แผนออกกำลังกาย & กิจกรรม',
            onTap: () => _safeGoNamed(context, AppRoute.fit),
          ),
        ],
      ),
      _MoreSection(
        title: 'Medical',
        items: [
          _MoreItem(
            icon: Icons.vaccines_outlined,
            title: 'Vaccines',
            subtitle: 'บันทึก/เตือนวัคซีน',
            onTap: () => _safeGoNamed(context, 'vaccines'), // เพิ่มใน AppRoute ภายหลัง
          ),
          _MoreItem(
            icon: Icons.medication_outlined,
            title: 'Medication',
            subtitle: 'รายการยา & เตือนเติมยา',
            onTap: () => _safeGoNamed(context, 'medication'), // เพิ่มใน AppRoute ภายหลัง
          ),
          _MoreItem(
            icon: Icons.watch_outlined,
            title: 'Wearables',
            subtitle: 'เชื่อมต่อ/ตั้งค่า Health Connect',
            onTap: () => _safeGoNamed(context, AppRoute.wearable),
          ),
        ],
      ),
      _MoreSection(
        title: 'Tools',
        items: [
          _MoreItem(
            icon: Icons.tune_outlined,
            title: 'Quick Panel',
            subtitle: 'ตั้งค่าปุ่มด่วนในแถบล่าง',
            onTap: () => _safeGoNamed(context, 'quick_panel'), // เพิ่มภายหลัง
          ),
          _MoreItem(
            icon: Icons.widgets_outlined,
            title: 'Manage Home Cards',
            subtitle: 'เลือกการ์ดที่จะแสดงบนหน้า Home',
            onTap: () => _safeGoNamed(context, 'manage_home_cards'), // เพิ่มภายหลัง
          ),
        ],
      ),
      if (kDebugMode) // ซ่อนไว้หลัง debug ก่อน
        _MoreSection(
          title: 'Admin (Dev only)',
          items: [
            _MoreItem(
              icon: Icons.campaign_outlined,
              title: 'Post Broadcast',
              subtitle: 'โพสต์ข่าวลงฟีด (ต้อง token admin)',
              onTap: () => _safeGoNamed(context, AppRoute.feed),
            ),
          ],
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final sec = sections[i];
          return _SectionCard(
            title: sec.title,
            children: sec.items
                .map((it) => _ItemTile(
                      icon: it.icon,
                      title: it.title,
                      subtitle: it.subtitle,
                      onTap: it.onTap,
                    ))
                .toList(),
          );
        },
      ),
      backgroundColor: cs.surface, // ให้เข้ากับธีม
    );
  }
}

// ---------- UI helpers (เบา & ดูแพงแบบกระจกบาง ๆ ไม่มี blur หนัก) ----------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อหมวด (บาง โปร่ง)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 6),
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withOpacity(0.9),
              ),
            ),
          ),
          const Divider(height: 10),
          ..._withDividers(children),
        ],
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> tiles) {
    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      out.add(tiles[i]);
      if (i != tiles.length - 1) {
        out.add(const Divider(height: 1));
      }
    }
    return out;
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Text(
                subtitle,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ---------- data models (ภายในไฟล์) ----------

class _MoreItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _MoreSection {
  final String title;
  final List<_MoreItem> items;
  _MoreSection({required this.title, required this.items});
}
