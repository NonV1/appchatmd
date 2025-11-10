// lib/features/home/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

import '../../core/user/session.dart';
import '../../core/data/health_repo.dart';
import '../../core/models/wearable_metrics.dart';
import '../../utils/format.dart' as fmt;
import '../../ui/widgets/feature_card.dart';
import '../../core/router/app_router.dart';
import '../wearables/widgets/wearable_home_card.dart';
import '../wearables/screens/wearable_screen.dart'; // (ไม่จำเป็นถ้าเรียกผ่าน route)

class HomeScreen extends StatefulWidget {
  static const route = '/';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _health = HealthRepo();
  WearableMetricsSnapshot? _metrics;
  String _greetName = 'User';
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final session = Session.I;
      final display = session.cachedDisplayName ?? await session.readDisplayName();
      final email   = session.cachedEmail ?? await session.readEmail();
      _greetName = (display != null && display.trim().isNotEmpty)
          ? display.trim()
          : (email?.split('@').first ?? 'User');

      _metrics = await _health.fetchToday(); // repo จะข้าม metric ที่อ่านไม่ได้
    } catch (_) {
      // no-op
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _metricText(String id) {
    final value = _metrics?.metrics[id];
    if (value == null) return null;
    final num v = value;
    switch (id) {
      case MetricIds.heartRate:            return fmt.fmtBpm(v);
      case MetricIds.steps:                return fmt.fmtSteps(v);
      case MetricIds.sleepSec:             return fmt.fmtHCompact(Duration(seconds: v.toInt()));
      case MetricIds.activeEnergyKcal:     return fmt.fmtKcal(v);
      case MetricIds.oxygenSaturationPct:  return fmt.fmtSpO2(v);
      default:                             return fmt.fmtInt(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t  = Theme.of(context);
    final cs = t.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hi, $_greetName',
                                style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(_loading ? 'Updating…' : 'Welcome back',
                                style: t.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                )),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person, color: cs.primary),
                      ),
                    ],
                  ),
                ),
              ),

              // ==== GRID (แบบ quilted) ====
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverQuiltedGridDelegate(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    repeatPattern: QuiltedGridRepeatPattern.inverted,
                    pattern: const [
                      QuiltedGridTile(2, 2), // ใหญ่ 2x2 — Wearable
                      QuiltedGridTile(1, 1), // AI
                      QuiltedGridTile(1, 1), // Screening
                      QuiltedGridTile(2, 1), // Food สูง
                      QuiltedGridTile(1, 1), // Fit
                      QuiltedGridTile(1, 1), // More
                    ],
                  ),
                  delegate: SliverChildListDelegate.fixed([
                    // 1) Wearable (ใหญ่)
                    RepaintBoundary(
                    child: WearableHomeCard(
                      metrics: _metrics?.metrics ?? const {},
                      onTap: () => context.push('/wearable'),
                    ),
                  ),

                    // 2) AI Chat
                    RepaintBoundary(
                      child: FeatureCard.glass(
                        title: 'AI',
                        subtitle: 'Ask anything',
                        icon: Icons.chat_bubble_outline,
                        onTap: () => context.pushNamed(AppRoute.aiDisclaimer),
                        blur: false,
                        elevated: false,
                        showModuleFrame: true,
                      ),
                    ),

                    // 3) Disease screening
                    RepaintBoundary(
                      child: FeatureCard.glass(
                        title: 'AI วิเคราะห์โรค',
                        subtitle: 'Screening',
                        icon: Icons.medical_services_outlined,
                        onTap: () => context.push('/ai_disease'),
                        blur: false,
                        elevated: false,
                        showModuleFrame: true,
                      ),
                    ),

                    // 4) Food (สูง)
                    RepaintBoundary(
                      child: SizedBox(
                        height: 220,
                        child: FeatureCard.glass(
                          title: 'Food',
                          subtitle: 'Nutrition',
                          icon: Icons.restaurant_outlined,
                          onTap: () => context.push('/food'),
                          blur: false,
                          elevated: false,
                          showModuleFrame: true,
                        ),
                      ),
                    ),

                    // 5) Fit
                    RepaintBoundary(
                      child: FeatureCard.glass(
                        title: 'Fit',
                        subtitle: 'Workout',
                        icon: Icons.fitness_center_outlined,
                        onTap: () => context.push('/fit'),
                        blur: false,
                        elevated: false,
                        showModuleFrame: true,
                      ),
                    ),

                    // 6) More
                    RepaintBoundary(
                      child: FeatureCard.glass(
                        title: 'More',
                        subtitle: 'Add feature',
                        icon: Icons.add_circle_outline,
                        onTap: () => context.push('/more'),
                        blur: false,
                        elevated: false,
                        showModuleFrame: true,
                      ),
                    ),
                  ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),

      // ===== FAB กลมกลาง =====
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/quick'),
        backgroundColor: cs.primary,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ===== BottomNav สไตล์ glass =====
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(20),
          blur: 8,
          color: cs.surface.withOpacity(.72),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.surface.withOpacity(.80), cs.primary.withOpacity(.06)],
          ),
          border: Border.all(color: cs.onSurface.withOpacity(.08), width: 1),
          shadowStrength: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavIcon(icon: Icons.home_rounded, label: 'Home', active: true,  onTap: () {}),
                _NavIcon(icon: Icons.article_outlined, label: 'Feed',         onTap: () => context.push('/feed')),
                const SizedBox(width: 44), // เว้นให้ FAB
                _NavIcon(icon: Icons.assignment_ind_outlined, label: 'Doctor', onTap: () => context.push('/doctor')),
                _NavIcon(icon: Icons.settings_outlined,       label: 'Settings', onTap: () => context.push('/settings')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = active ? cs.primary : cs.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
