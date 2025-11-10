// lib/utils/platform.dart
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class PlatformUtils {
  PlatformUtils._();

  static bool get isAndroid => Platform.isAndroid;
  static bool get isiOS => Platform.isIOS;

  /// ประมาณการ “เครื่องสเปกต่ำ” เพื่อเลือกปิด blur/ลด motion
  static Future<bool> isLowSpecDevice() async {
    final info = DeviceInfoPlugin();
    try {
      if (isAndroid) {
        final a = await info.androidInfo;
        final sdk = a.version.sdkInt ?? 0;
        // เกณฑ์คร่าวๆ: Android <= 28 (Pie) และ/หรือ RAM ต่ำ (ไม่อ่านตรงๆ ได้)
        return sdk <= 28;
      } else if (isiOS) {
        final i = await info.iosInfo;
        // เครื่องเก่ากว่า iPhone 8/SE2 จะช้ากับ blur มาก
        final model = (i.utsname.machine ?? '').toLowerCase();
        final old = [
          'iphone7,2','iphone7,1','iphone8,1','iphone8,2','iphone8,4', // 6/6+/SE1
          'iphone9,1','iphone9,3','iphone9,2','iphone9,4',             // 7/7+
        ];
        return old.any(model.contains);
      }
    } catch (_) {/* ignore */}
    return false;
  }

  /// สั่นเบา ๆ (มีเช็คแพลตฟอร์มแล้ว)
  static Future<void> lightHaptic() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
