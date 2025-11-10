import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

import 'package:chatmd_v1/core/data/feed_repo.dart';
import 'package:chatmd_v1/ui/widgets/net_state_banner.dart';
import 'package:chatmd_v1/ui/widgets/section_header.dart';
import 'package:chatmd_v1/theme/app_theme.dart';
import 'package:chatmd_v1/ui/widgets/glass_backdrop.dart';

/// ฟีดข่าวการแพทย์ (เรียบหรู + glass + ประหยัดสเปก)
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _repo = FeedRepo();
  late Future<List<FeedItem>> _future;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchLatest();
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    try {
      final f = _repo.fetchLatest();
      setState(() => _future = f);
      await f;
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Medical Feed')),
      body: GlassBackdrop(
        useBlur: false, // เปิด true ได้ถ้าทดสอบแล้วไม่หน่วง
        children: [
          // แบนเนอร์บอกสถานะเน็ต/เซิร์ฟเวอร์ (ถ้ามี)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: NetStateBanner.auto(compact: true),
          ),
          // เนื้อหาหลัก
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: cs.primary,
              child: FutureBuilder<List<FeedItem>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting && !_refreshing) {
                    return _buildLoadingList(context);
                  }
                  if (snap.hasError) {
                    return _buildError(context, snap.error.toString());
                  }
                  final items = snap.data ?? const <FeedItem>[];
                  if (items.isEmpty) {
                    return _buildEmpty(context);
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      t.spacing.horizontal, 12, t.spacing.horizontal, 24),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        final header = SectionHeader(
                          title: 'Today’s updates',
                          subtitle: 'Evidence-based summaries for everyone',
                        );
                        return AnimatedOpacity(
                          opacity: 1.0,
                          duration: 300.ms,
                          child: header,
                        );
                      }
                      final item = items[i - 1];
                      return _FeedGlassTile(item: item);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        t.spacing.horizontal, 12, t.spacing.horizontal, 24),
      itemCount: 6,
      itemBuilder: (_, __) => const _SkeletonTile(),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 36),
          const SizedBox(height: 8),
          Text('Failed to load feed', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(msg, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.6),
          ), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => setState(() => _future = _repo.fetchLatest()),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_books_outlined, size: 36, color: cs.onSurface.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text('No articles yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Please check back later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

/// การ์ดข่าวแบบ glass ใส เบา (ใช้ glassmorphism_ui)
class _FeedGlassTile extends StatelessWidget {
  const _FeedGlassTile({required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    final cs = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: GlassContainer(
        borderRadius: t.radius,
        blur: 10, // เบลอแค่ตัวการ์ด (เบากว่าเบลอทั้งฉาก)
        color: cs.surface.withOpacity(0.12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surface.withOpacity(0.10),
            cs.primary.withOpacity(0.18),
          ],
        ),
        border: Border.all(color: cs.onSurface.withOpacity(0.16), width: 1),
        shadowStrength: 6,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // รูป preview (ถ้ามี)
              _Thumb(url: item.imageUrl),
              const SizedBox(width: 12),
              // เนื้อหา
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    if (item.summary?.isNotEmpty == true)
                      Text(
                        item.summary!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withOpacity(0.70),
                            ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: cs.onSurface.withOpacity(0.55)),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(item.publishedAt),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: cs.onSurface.withOpacity(0.70),
                              ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.55)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 200.ms, curve: Curves.easeOut)
          .moveY(begin: 8, end: 0, duration: 200.ms, curve: Curves.easeOut),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        height: 72,
        color: cs.primary.withOpacity(0.10),
        child: url == null || url!.isEmpty
            ? Icon(Icons.medical_information_outlined,
                color: cs.primary.withOpacity(0.6))
            : Image.network(url!, fit: BoxFit.cover),
      ),
    );
  }
}

/// โครงกระดูกระหว่างโหลด (ไม่พึ่งแพ็กเกจภายนอก)
class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);
    final cs = Theme.of(context).colorScheme;

    return GlassContainer(
      borderRadius: t.radius,
      blur: 0,
      color: cs.surface.withOpacity(0.10),
      border: Border.all(color: cs.onSurface.withOpacity(0.10), width: 1),
      shadowStrength: 4,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // รูป
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            // แท่งข้อความปลอม
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(cs, 0.22, 16),
                  const SizedBox(height: 8),
                  _bar(cs, 0.18, 16),
                  const SizedBox(height: 10),
                  _bar(cs, 0.12, 14, widthFactor: 0.4),
                ],
              ),
            )
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1200.ms);
  }

  Widget _bar(ColorScheme cs, double opacity, double height, {double widthFactor = 1}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(opacity),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
