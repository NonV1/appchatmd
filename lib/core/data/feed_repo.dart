// lib/core/data/feed_repo.dart
import 'dart:async';

import '../api/http_client.dart';

/// ------------------------------
/// Feed Models (เบา ๆ ใช้ได้เลย)
/// ------------------------------
class FeedItem {
  FeedItem({
    required this.id,
    required this.title,
    this.summary,
    this.imageUrl,
    DateTime? publishedAt,
    this.tags = const [],
  }) : publishedAt = publishedAt ?? DateTime.now();

  final String id;
  final String title;
  final String? summary;
  final String? imageUrl;
  final DateTime publishedAt;
  final List<String> tags;

  factory FeedItem.fromJson(Map<String, dynamic> m) {
    return FeedItem(
      id: (m['id'] ?? m['uuid'] ?? m['post_id'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      summary: (m['summary'] ?? m['content'] ?? m['excerpt'])?.toString(),
      imageUrl: (m['image'] ?? m['image_url'])?.toString(),
      publishedAt: _parseDt(m['published_at'] ?? m['created_at']),
      tags: _parseTags(m['tags']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'image_url': imageUrl,
        'published_at': publishedAt.toIso8601String(),
        'tags': tags,
      };

  static DateTime _parseDt(dynamic v) {
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    return DateTime.now();
  }

  static List<String> _parseTags(dynamic v) {
    if (v is List) return v.whereType<String>().toList(growable: false);
    return const [];
  }
}

/// ------------------------------
/// FeedRepo
/// ------------------------------
/// - ดึง /feed รองรับทั้งรูปแบบ:
///   1) `[ {...}, {...} ]`
///   2) `{ "items": [ ... ], "next_cursor": "..." }`
/// - มีแคชในหน่วยความจำ + สตรีมให้ UI subscribe ได้
/// - รองรับ loadMore() ผ่าน cursor ถ้ามี
class FeedRepo {
  FeedRepo({ApiClient? api, Duration throttle = const Duration(seconds: 5)})
      : _api = api ?? HttpClient.I.rawClient,
        _throttle = throttle;

  final ApiClient _api;
  final Duration _throttle;

  final _controller = StreamController<List<FeedItem>>.broadcast();
  List<FeedItem> _items = const [];
  String? _nextCursor;
  DateTime? _lastFetchAt;

  Stream<List<FeedItem>> watch() => _controller.stream;

  List<FeedItem> get cached => _items;

  String? get nextCursor => _nextCursor;

  bool get hasMore => _nextCursor != null && _nextCursor!.isNotEmpty;

  /// โหลดชุดแรก (หรือ refresh)
  Future<List<FeedItem>> loadInitial({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastFetchAt != null && now.difference(_lastFetchAt!) < _throttle) {
      // ป้องกันสแปมรีเฟรชถี่
      return _items;
    }

    final res = await _api.get('/feed');
    final parsed = _parseFeedResponse(res);

    _items = parsed.items;
    _nextCursor = parsed.nextCursor;
    _lastFetchAt = now;

    _controller.add(_items);
    return _items;
  }

  /// Alias ให้ UI ใช้ชื่ออ่านง่าย
  Future<List<FeedItem>> fetchLatest({bool force = false}) =>
      loadInitial(force: force);

  /// โหลดเพิ่ม (ถ้าแบ็กเอนด์รองรับ `?cursor=...`)
  Future<List<FeedItem>> loadMore() async {
    if (!hasMore) return _items;

    final res = await _api.get('/feed', query: {'cursor': _nextCursor});
    final parsed = _parseFeedResponse(res);

    // กันซ้ำตาม id
    final existing = {for (final p in _items) p.id: p};
    for (final p in parsed.items) {
      existing.putIfAbsent(p.id, () => p);
    }

    _items = existing.values.toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt)); // ใหม่ขึ้นก่อน
    _nextCursor = parsed.nextCursor;
    _controller.add(_items);
    return _items;
  }

  /// เคลียร์แคช (เช่น ตอน logout)
  void clearCache() {
    _items = const [];
    _nextCursor = null;
    _controller.add(_items);
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  /// ------------------------------
  /// Admin endpoints (เตรียมไว้พร้อมใช้ทีหลัง)
  /// ------------------------------
  Future<FeedItem> adminCreateDraft({
    required String title,
    String? summary,
    String? imageUrl,
    List<String>? tags,
  }) async {
    final res = await _api.post('/admin/posts', body: {
      'title': title,
      if (summary != null) 'summary': summary,
      if (imageUrl != null) 'image_url': imageUrl,
      if (tags != null) 'tags': tags,
    });
    final post = FeedItem.fromJson((res as Map).cast<String, dynamic>());
    // อัปเดตแคชให้เห็นทันที (ยังเป็น draft ก็ได้ขึ้นอยู่กับฝั่งเซิร์ฟเวอร์)
    _items = [post, ..._items];
    _controller.add(_items);
    return post;
  }

  Future<void> adminPublish(String postId) async {
    await _api.post('/admin/posts/$postId/publish');
    // ให้ UI ไป refresh เอง (ไม่เดา state ฝั่งเซิร์ฟเวอร์)
  }

  Future<void> adminDelete(String postId) async {
    await _api.delete('/admin/posts/$postId');
    _items = _items.where((p) => p.id != postId).toList(growable: false);
    _controller.add(_items);
  }

  /// ------------------------------
  /// Helpers
  /// ------------------------------
  _ParsedFeed _parseFeedResponse(dynamic res) {
    if (res is List) {
      final items = res
          .whereType<Map>()
          .map((e) => FeedItem.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
      return _ParsedFeed(items: items, nextCursor: null);
    }
    if (res is Map) {
      final list = (res['items'] ?? res['data'] ?? res['results']);
      final next = res['next_cursor'] ?? res['next'] ?? res['cursor'];
      final items = (list is List)
          ? list
              .whereType<Map>()
              .map((e) => FeedItem.fromJson(e.cast<String, dynamic>()))
              .toList(growable: false)
          : const <FeedItem>[];
      final cursor = (next is String && next.isNotEmpty) ? next : null;
      return _ParsedFeed(items: items, nextCursor: cursor);
    }
    // รูปแบบไม่คาดคิด — คืนลิสต์ว่าง
    return const _ParsedFeed(items: [], nextCursor: null);
  }
}

class _ParsedFeed {
  const _ParsedFeed({required this.items, required this.nextCursor});
  final List<FeedItem> items;
  final String? nextCursor;
}
