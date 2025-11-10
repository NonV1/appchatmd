// lib/utils/connectivity.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// สถานะละเอียดสำหรับ UI ทั่วไป
enum NetState { onlineWifi, onlineMobile, onlineOther, offline }

extension NetStateX on NetState {
  bool get isOnline =>
      this == NetState.onlineWifi ||
      this == NetState.onlineMobile ||
      this == NetState.onlineOther;

  String get label => switch (this) {
        NetState.onlineWifi   => 'Wi-Fi connected',
        NetState.onlineMobile => 'Mobile data connected',
        NetState.onlineOther  => 'Connected',
        NetState.offline      => 'No internet connection',
      };
}

/// === Shim ให้เข้ากับโค้ดเก่าที่เรียก statusStream/ConnectivityStatus ===
enum ConnectivityStatus { online, offline }

class ConnectivityWatcher {
  ConnectivityWatcher._();
  static final ConnectivityWatcher I = ConnectivityWatcher._();

  final _controller = StreamController<NetState>.broadcast();
  StreamSubscription<dynamic>? _sub; // รองรับทั้ง ConnectivityResult และ List<ConnectivityResult>

  /// สตรีมละเอียด
  Stream<NetState> get stream => _controller.stream;

  /// สตรีมย่อ (ตามสัญญาเดิมของหน้า UI)
  Stream<ConnectivityStatus> get statusStream =>
      stream.map((s) => s.isOnline ? ConnectivityStatus.online : ConnectivityStatus.offline);

  /// อ่านสถานะปัจจุบันครั้งเดียว
  Future<NetState> current() async {
    final result = await Connectivity().checkConnectivity();
    return _mapDynamic(result);
  }

  /// เริ่มเฝ้าสถานะ (เรียกครั้งเดียวก็พอ)
  void start() {
    if (_sub != null) return;

    // seed ค่าเริ่มต้นให้ UI เห็นทันที
    current().then((s) {
      if (!_controller.isClosed) _controller.add(s);
    });

    // รองรับทั้ง signature เก่า/ใหม่ของ connectivity_plus
    _sub = Connectivity().onConnectivityChanged.listen((dynamic event) {
      // event อาจเป็น ConnectivityResult (เวอร์ชันใหม่)
      // หรือ List<ConnectivityResult> (เวอร์ชันเก่า)
      final mapped = _mapDynamic(event);
      if (!_controller.isClosed) _controller.add(mapped);
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }

  // ---- mapping helpers ----
  NetState _mapDynamic(dynamic value) {
    if (value is ConnectivityResult) {
      return _mapOne(value);
    }
    if (value is List<ConnectivityResult>) {
      return _mapList(value);
    }
    // เผื่อกรณีไม่รู้จักรูปแบบ
    return NetState.offline;
  }

  NetState _mapOne(ConnectivityResult r) {
    switch (r) {
      case ConnectivityResult.wifi:      return NetState.onlineWifi;
      case ConnectivityResult.mobile:    return NetState.onlineMobile;
      case ConnectivityResult.ethernet:  return NetState.onlineOther;
      case ConnectivityResult.vpn:       return NetState.onlineOther;
      case ConnectivityResult.bluetooth: return NetState.onlineOther;
      case ConnectivityResult.other:     return NetState.onlineOther;
      case ConnectivityResult.none:      return NetState.offline;
    }
  }

  NetState _mapList(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi))     return NetState.onlineWifi;
    if (results.contains(ConnectivityResult.mobile))   return NetState.onlineMobile;
    if (results.contains(ConnectivityResult.ethernet)) return NetState.onlineOther;
    if (results.contains(ConnectivityResult.vpn))      return NetState.onlineOther;
    if (results.contains(ConnectivityResult.other))    return NetState.onlineOther;
    return NetState.offline;
  }
}
