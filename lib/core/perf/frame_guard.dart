// lib/core/perf/frame_guard.dart
//
// Utilities สำหรับจัดคิวงานให้ “ลื่น” บนเฟรมเรนเดอร์:
// - runNextFrame(): รันงานหลังเฟรมถัดไป (post-frame)
// - runAfterIdle(): รันงานเมื่อระบบว่าง (scheduleWarmUpFrame + delay)
// - throttle(): กันสแปมงานซ้ำภายในช่วงเวลา
// - profile(): วัดเวลาทำงาน/เตือนเมื่อเกิน threshold (debug เท่านั้น)
// - warmUpShadersSafe(): อุ่นเครื่อง shader/ตั้งค่า image cache เบา ๆ
//
// ใช้แบบ singleton: FrameGuard.I

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class FrameGuard {
  FrameGuard._();
  static final FrameGuard I = FrameGuard._();

  /// โหมดประหยัดพลัง/ลดอนิเมชัน
  /// (ผูกกับ Settings เพื่อปิด blur/animation ได้ง่าย)
  final ValueNotifier<bool> lowPowerMode = ValueNotifier<bool>(false);

  /// เก็บเวลาครั้งล่าสุดของงานที่ถูก throttle ด้วย key
  final Map<String, int> _lastMicros = <String, int>{};

  /// งานที่ตั้งคิวไว้ต่อ key (เพื่อยกเลิก/ทับได้)
  final Map<String, Timer> _pending = <String, Timer>{};

  /// เรียก [fn] หลังจากวาดเฟรมปัจจุบันเสร็จ
  void runNextFrame(VoidCallback fn) {
    SchedulerBinding.instance.addPostFrameCallback((_) => fn());
  }

  /// รันงานเมื่อ “ระบบว่าง” เล็กน้อย (เหมาะกับงานเบื้องหลัง/IO เบา ๆ)
  void runAfterIdle(
    VoidCallback fn, {
    Duration minDelay = const Duration(milliseconds: 50),
  }) {
    // บังคับให้มี WarmUpFrame รอบใหม่ แล้วค่อยรอ minDelay
    SchedulerBinding.instance.scheduleWarmUpFrame();
    Timer(minDelay, fn);
  }

  /// ป้องกันการเรียกงานซ้ำถี่ ๆ ในช่วง [window]
  /// คืน true ถ้า “อนุญาตให้เรียก” ในรอบนี้
  bool throttle(String key, Duration window) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final last = _lastMicros[key] ?? 0;
    if (now - last >= window.inMicroseconds) {
      _lastMicros[key] = now;
      return true;
    }
    return false;
  }

  /// Schedule งานแบบทับงานเดิม (debounce) ต่อ [key]
  void debounce(String key, Duration wait, VoidCallback fn) {
    _pending[key]?.cancel();
    _pending[key] = Timer(wait, () {
      _pending.remove(key);
      fn();
    });
  }

  /// ยกเลิกงาน debounce ตาม [key]
  void cancelDebounce(String key) {
    _pending.remove(key)?.cancel();
  }

  /// วัดเวลาการทำงาน (sync/async) — debug เท่านั้น
  Future<T> profile<T>(
    String label,
    FutureOr<T> Function() fn, {
    Duration warnOver = const Duration(milliseconds: 16), // > 1 เฟรม 60fps
  }) async {
    final sw = Stopwatch()..start();
    try {
      final res = await Future.sync(fn);
      return res;
    } finally {
      sw.stop();
      if (kDebugMode && sw.elapsed >= warnOver) {
        // ignore: avoid_print
        print('[FrameGuard] $label took ${sw.elapsed.inMilliseconds} ms');
      }
    }
  }

  /// อุ่นเครื่อง shader/ลด cache miss แบบปลอดภัย (เรียกหนึ่งครั้งตอน boot)
  /// - ปรับ ImageCache ให้พอดี ๆ กับอุปกรณ์รุ่นเก่า
  /// - scheduleWarmUpFrame เพื่อให้เฟรมแรกไหลลื่น
  Future<void> warmUpShadersSafe({
    int? imageCacheMaxSize,
    int? imageCacheMaxMemoryBytes,
  }) async {
    final painting = PaintingBinding.instance;
    // ปรับขนาด cache แบบ conservative (ช่วยรุ่นเก่า ๆ)
    final cache = painting.imageCache;
    if (imageCacheMaxSize != null) {
      cache.maximumSize = math.max(100, imageCacheMaxSize);
    }
    if (imageCacheMaxMemoryBytes != null) {
      cache.maximumSizeBytes =
          math.max(40 * 1024 * 1024, imageCacheMaxMemoryBytes); // min 40MB
    }
    // กระตุ้นให้มี warm-up frame
    SchedulerBinding.instance.scheduleWarmUpFrame();
    // หน่วงเล็กน้อยให้ pipeline ว่าง
    await Future<void>.delayed(const Duration(milliseconds: 8));
  }
}

/// Helper: ใช้กับ State ที่อยาก “เลื่อน setState ไปหลังเฟรม”
mixin PostFrameMixin<T extends StatefulWidget> on State<T> {
  void setStateNextFrame(VoidCallback fn) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ignore: invalid_use_of_protected_member
      setState(fn);
    });
  }
}

/// Helper: ใช้ครอบ subtree ที่ render หนัก ให้ build พร้อมกันได้ทีละน้อย
/// ใช้ร่วมกับ lowPowerMode ได้ (ถ้าเปิด — ลดจำนวนลูกที่วาด)
class ProgressiveListGate extends StatefulWidget {
  const ProgressiveListGate({
    super.key,
    required this.children,
    this.batch = 8,
    this.interval = const Duration(milliseconds: 16),
    this.resetOnUpdate = false,
  });

  final List<Widget> children;
  final int batch; // จำนวนที่ปล่อย/เฟรม
  final Duration interval;
  final bool resetOnUpdate;

  @override
  State<ProgressiveListGate> createState() => _ProgressiveListGateState();
}

class _ProgressiveListGateState extends State<ProgressiveListGate> {
  int _visible = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _kick();
  }

  @override
  void didUpdateWidget(covariant ProgressiveListGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetOnUpdate || oldWidget.children.length != widget.children.length) {
      _t?.cancel();
      _visible = 0;
      _kick();
    }
  }

  void _kick() {
    _t?.cancel();
    _t = Timer.periodic(widget.interval, (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        _visible = math.min(widget.children.length, _visible + widget.batch);
      });
      if (_visible >= widget.children.length) timer.cancel();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lowPower = FrameGuard.I.lowPowerMode.value;
    final target = lowPower ? math.min(_visible, 12) : _visible;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widget.children.take(target).toList(growable: false),
    );
  }
}
