// \lib\ui\widgets\net_state_banner.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../core/api/http_client.dart';

/// สถานะเครือข่าย/เซิร์ฟเวอร์
enum NetState { ok, noInternet, serverDown }

/// แบนเนอร์แจ้งเตือนสถานะเน็ต/เซิร์ฟเวอร์
/// - ใช้แบบกำหนดสถานะเอง (คุมจากภายนอก) ด้วย [state]
/// - หรือใช้เวอร์ชันอัตโนมัติ [NetStateBanner.auto] ให้ตรวจเองทุก ๆ 30 วินาที
class NetStateBanner extends StatelessWidget {
  const NetStateBanner({
    super.key,
    required this.state,
    this.onRetry,
    this.compact = false,
  });

  final NetState state;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (state == NetState.ok) return const SizedBox.shrink();
    final t = AppTheme.tokensOf(context);

    String title;
    String subtitle;
    Color color;

    switch (state) {
      case NetState.noInternet:
        title = 'ไม่มีอินเทอร์เน็ต';
        subtitle = 'ตรวจสอบการเชื่อมต่อของคุณ';
        color = t.warning;
        break;
      case NetState.serverDown:
        title = 'ระบบขัดข้อง';
        subtitle = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้';
        color = t.danger;
        break;
      default:
        title = '';
        subtitle = '';
        color = t.warning;
    }

    final content = Row(
      children: [
        Icon(Icons.wifi_off_rounded, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: t.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: t.onSurface.withOpacity(0.85))),
            ],
          ),
        ),
        if (onRetry != null)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('ลองใหม่'),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Glass.panel(
        t: t,
        useBlur: false,
        elevated: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: content,
      ),
    );
  }

  /// เวอร์ชันอัตโนมัติ—เช็คทั้งอินเทอร์เน็ตและ /health
  static Widget auto({
    Key? key,
    HttpClient? http,
    Duration pingInterval = const Duration(seconds: 30),
    bool compact = false,
  }) {
    return _NetStateAuto(
      key: key,
      http: http ?? HttpClient.I,
      pingInterval: pingInterval,
      compact: compact,
    );
  }
}

class _NetStateAuto extends StatefulWidget {
  const _NetStateAuto({
    super.key,
    required this.http,
    required this.pingInterval,
    required this.compact,
  });

  final HttpClient http;
  final Duration pingInterval;
  final bool compact;

  @override
  State<_NetStateAuto> createState() => _NetStateAutoState();
}

class _NetStateAutoState extends State<_NetStateAuto> {
  NetState _state = NetState.ok;

  // เดิม: StreamSubscription? _connSub;
  // แก้เป็น dynamic เพื่อรับได้ทั้ง ConnectivityResult และ List<ConnectivityResult>
  StreamSubscription<dynamic>? _connSub;

  Timer? _timer;

  // เดิมคงไว้ได้ แต่เราจะแปลง event ให้เป็นชนิดนี้เสมอ
  ConnectivityResult _lastConn = ConnectivityResult.none;

  @override
  void initState() {
    super.initState();
    // ติดตาม Connectivity (รองรับทั้ง 2 signature ของแพ็กเกจ)
    _connSub = Connectivity().onConnectivityChanged.listen((dynamic event) {
      _lastConn = _pickOne(event); // แปลงทุกกรณีให้เหลือ ConnectivityResult เดี่ยว
      _recompute();
    });

    // ตรวจทันที + ตามรอบ
    _ping();
    _timer = Timer.periodic(widget.pingInterval, (_) => _ping());
  }

  // ===== เพิ่ม helper สำหรับ map event ให้เป็น ConnectivityResult เดี่ยว =====
  ConnectivityResult _pickOne(dynamic event) {
    if (event is ConnectivityResult) return event;

    if (event is List<ConnectivityResult>) {
      if (event.isEmpty) return ConnectivityResult.none;

      // จัดลำดับความสำคัญเครือข่ายที่มักพบ
      if (event.contains(ConnectivityResult.wifi)) return ConnectivityResult.wifi;
      if (event.contains(ConnectivityResult.mobile)) return ConnectivityResult.mobile;
      if (event.contains(ConnectivityResult.ethernet)) return ConnectivityResult.ethernet;
      if (event.contains(ConnectivityResult.vpn)) return ConnectivityResult.vpn;
      if (event.contains(ConnectivityResult.bluetooth)) return ConnectivityResult.bluetooth;
      if (event.contains(ConnectivityResult.other)) return ConnectivityResult.other;
      if (event.contains(ConnectivityResult.none)) return ConnectivityResult.none;

      // เผื่ออนาคตมีชนิดใหม่ ๆ
      return event.first;
    }

    // รูปแบบไม่รู้จัก → ถือว่า offline ไว้ก่อน
    return ConnectivityResult.none;
  }

  Future<void> _ping() async {
    try {
      final ok = await widget.http.pingHealth();
      if (!mounted) return;
      if (_noInternet(_lastConn)) {
        setState(() => _state = NetState.noInternet);
      } else {
        setState(() => _state = ok ? NetState.ok : NetState.serverDown);
      }
    } catch (_) {
      if (!mounted) return;
      if (_noInternet(_lastConn)) {
        setState(() => _state = NetState.noInternet);
      } else {
        setState(() => _state = NetState.serverDown);
      }
    }
  }

  void _recompute() {
    if (_noInternet(_lastConn)) {
      setState(() => _state = NetState.noInternet);
    } else {
      // ออนไลน์แล้ว ให้ผล ping เป็นคนตัดสิน ok/serverDown
      _ping();
    }
  }

  bool _noInternet(ConnectivityResult r) => r == ConnectivityResult.none;

  @override
  void dispose() {
    _connSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NetStateBanner(
      state: _state,
      compact: widget.compact,
      onRetry: _ping,
    );
  }
}