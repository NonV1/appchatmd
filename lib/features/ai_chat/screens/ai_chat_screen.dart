// lib/features/ai_chat/screens/ai_chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/http_client.dart';
import '../../../utils/connectivity.dart';
import '../../../core/data/health_repo.dart';
import '../../../core/models/wearable_metrics.dart'; // เพื่ออ้างอิง id มาตรฐาน
import '../../auth/widgets/glass_card.dart'; // ใช้การ์ดกระจกให้โทนเดียวกับทั้งแอป

/// โครงข้อความในห้องแชท
class ChatMsg {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  ChatMsg({required this.role, required this.content});
}

/// หน้าแชท AI (มีแบนเนอร์คำเตือน, ดึง metric จาก Wearables แนบกับคำถาม)
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  final _messages = <ChatMsg>[
    ChatMsg(
      role: 'assistant',
      content:
          'สวัสดีค่ะ ฉันคือผู้ช่วยด้านสุขภาพ (ทดลองใช้)\n'
          'คำแนะนำนี้ไม่ใช่การวินิจฉัยทางการแพทย์ หากมีอาการรุนแรงให้ไปพบแพทย์ทันทีค่ะ',
    ),
  ];

  bool _sending = false;
  bool _serverDown = false;
  bool _offline = false;

  // สำหรับแนบ metrics จาก wearable รอบส่งข้อความล่าสุด
  Map<String, num> _latestMetrics = {};

  @override
  void initState() {
    super.initState();
    // เฝ้าเน็ตไว้เพื่อโชว์สถานะ “ออฟไลน์”
    ConnectivityWatcher.I.statusStream.listen((s) {
      if (!mounted) return;
      setState(() => _offline = (s == ConnectivityStatus.offline));
    });
    // ดึง metrics ตั้งต้น (ไม่บังคับ ถ้าไม่ได้อนุญาต/ไม่มี จะปล่อยว่าง)
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    try {
      final repo = HealthRepo();
      final snap = await repo.fetchToday();
      if (!mounted) return;
      setState(() => _latestMetrics = Map<String, num>.from(snap.metrics));
    } catch (_) {
      // เงียบ ๆ: ถ้าอ่านไม่ได้ก็ไม่บังคับ
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    // guard: สถานะเน็ต/เซิร์ฟเวอร์
    if (_offline) {
      _showSnack('ไม่มีการเชื่อมต่ออินเทอร์เน็ต');
      return;
    }

    setState(() {
      _sending = true;
      _serverDown = false;
      _messages.add(ChatMsg(role: 'user', content: text));
      _controller.clear();
    });

    // เลื่อนลงล่าง
    await Future.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }

    // อัปเดต metrics เฉพาะตอนส่ง (จะได้ค่อนข้างสด)
    await _loadMetrics();

    try {
      // รูปแบบ payload ไป backend (คุณจะไปต่อเข้ากับ OpenAI/รุ่นของคุณใน server)
      final payload = {
        'messages': _messages
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(growable: false),
        // แนบ metric เท่าที่มี (ไม่บังคับ ต้องเป็น id ตามมาตรฐานเรานะ)
        'metrics': _latestMetrics,
      };

      final res = await HttpClient.I.postJson('/ai/chat', payload);
      final text = (res.data['reply'] ?? '').toString();

      setState(() {
        _messages.add(ChatMsg(role: 'assistant', content: text.isEmpty ? '…' : text));
      });
    } catch (e) {
      setState(() => _serverDown = true);
      _showSnack('เซิร์ฟเวอร์ขัดข้อง ชั่วคราว');
    } finally {
      if (mounted) setState(() => _sending = false);
      // auto scroll
      await Future.delayed(const Duration(milliseconds: 50));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 160,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _handleBack() {
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => context.go('/'),
          ),
          title: const Text('AI Chat'),
        actions: [
          IconButton(
            tooltip: 'อ่านข้อกำหนด/คำเตือน',
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push('/ai_disclaimer'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Latest Vital Signs
          if (_latestMetrics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                backgroundOpacity: 0.10,
                borderOpacity: 0.20,
                blurSigma: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vital Sign:',
                      style: t.textTheme.titleSmall?.copyWith(
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (_latestMetrics.containsKey('heart_rate'))
                          Column(
                            children: [
                              Icon(Icons.favorite, color: cs.primary),
                              Text('${_latestMetrics['heart_rate']?.round() ?? 0} bpm'),
                            ],
                          ),
                        if (_latestMetrics.containsKey('oxygen_saturation_pct'))
                          Column(
                            children: [
                              Icon(Icons.air, color: cs.primary),
                              Text('${_latestMetrics['oxygen_saturation_pct']?.round() ?? 0}%'),
                            ],
                          ),
                        if (_latestMetrics.containsKey('steps'))
                          Column(
                            children: [
                              Icon(Icons.directions_walk, color: cs.primary),
                              Text('${_latestMetrics['steps']?.round() ?? 0}'),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // แบนเนอร์คำเตือน + ปุ่มไปหน้าข้อกำหนด
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              backgroundOpacity: 0.10,
              borderOpacity: 0.20,
              blurSigma: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.health_and_safety_outlined,
                      color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'คำแนะนำนี้มีเพื่อการให้ข้อมูลเท่านั้น ไม่ใช่การวินิจฉัยจากแพทย์\n'
                      'หากมีอาการรุนแรงให้ไปพบแพทย์ทันที',
                      style: t.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/ai_disclaimer'),
                    child: const Text('อ่านเพิ่ม'),
                  ),
                ],
              ),
            ),
          ),

          // สถานะเน็ต/เซิร์ฟเวอร์ (ถ้ามี)
          if (_offline || _serverDown)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                backgroundOpacity: 0.08,
                borderOpacity: 0.18,
                blurSigma: 8,
                child: Row(
                  children: [
                    Icon(
                      _offline ? Icons.wifi_off : Icons.cloud_off,
                      color: cs.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _offline
                            ? 'ออฟไลน์: กรุณาเชื่อมต่ออินเทอร์เน็ต'
                            : 'เซิร์ฟเวอร์ขัดข้อง: ลองใหม่อีกครั้งภายหลัง',
                        style: t.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.85),
                        ),
                      ),
                    ),
                    if (!_offline)
                      TextButton(
                        onPressed: _send,
                        child: const Text('ลองใหม่'),
                      ),
                  ],
                ),
              ),
            ),

          // รายการข้อความ
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isMe = m.role == 'user';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      backgroundOpacity: isMe ? 0.18 : 0.10,
                      borderOpacity: isMe ? 0.25 : 0.18,
                      blurSigma: 8,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Text(
                          m.content,
                          style: t.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // อินพุต + ปุ่มส่ง
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 2, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'พิมพ์คำถามด้านสุขภาพ…',
                      prefixIcon: const Icon(Icons.chat_bubble_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('ส่ง'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
