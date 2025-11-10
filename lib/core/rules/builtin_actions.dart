// lib/core/rules/builtin_actions.dart
import '../models/action.dart';

/// -------------------- NOTIFY (In-App / System) --------------------

/// แจ้งเตือนทั่วไป (ระดับ info)
ActionSpec notifyInfo({
  required String title,
  String? body,
  Map<String, dynamic>? extra,
}) {
  return ActionSpec.notify(
    title: title,
    body: body,
    payload: {
      'level': 'info', // executor จะแปลงเป็นสี/สไตล์เอง
      if (extra != null) ...extra,
    },
  );
}

/// แจ้งเตือนระดับเตือน (warning)
ActionSpec notifyWarning({
  required String title,
  String? body,
  Map<String, dynamic>? extra,
}) {
  return ActionSpec.notify(
    title: title,
    body: body,
    payload: {
      'level': 'warning',
      if (extra != null) ...extra,
    },
  );
}

/// แจ้งเตือนระดับวิกฤต (critical)
ActionSpec notifyCritical({
  required String title,
  String? body,
  Map<String, dynamic>? extra,
}) {
  return ActionSpec.notify(
    title: title,
    body: body,
    payload: {
      'level': 'critical',
      if (extra != null) ...extra,
    },
  );
}

/// -------------------- SURFACE CARD (ดันการ์ดขึ้นพื้นที่เฉพาะ) --------------------

/// ดันการ์ดขึ้นในโซน “เฉพาะคุณ / for_you”
ActionSpec surfaceForYouCard(String cardId, {Map<String, dynamic>? extra}) {
  return ActionSpec.surfaceCard(
    featureId: 'for_you',
    cardId: cardId,
    extra: extra,
  );
}

/// ดันการ์ดขึ้นในโซนฟีเจอร์ (กำหนดชื่อโซนเอง)
ActionSpec surfaceFeatureCard({
  required String featureId,
  required String cardId,
  Map<String, dynamic>? extra,
}) {
  return ActionSpec.surfaceCard(
    featureId: featureId,
    cardId: cardId,
    extra: extra,
  );
}

/// -------------------- NAVIGATION (เปิดหน้าในแอป) --------------------

/// เปิดหน้า wearables (รายละเอียดค่าจากนาฬิกา)
ActionSpec openWearables({Map<String, dynamic>? args}) {
  return ActionSpec.openRoute(route: '/wearables', args: args);
}

/// เปิดหน้า “เฉพาะคุณ”
ActionSpec openForYou({Map<String, dynamic>? args}) {
  return ActionSpec.openRoute(route: '/for-you', args: args);
}

/// เปิดหน้าใด ๆ ตามเส้นทาง
ActionSpec openRoute(String route, {Map<String, dynamic>? args}) {
  return ActionSpec.openRoute(route: route, args: args);
}

/// -------------------- LOG (บันทึกเหตุการณ์เพื่อวิเคราะห์) --------------------

ActionSpec logEvent(String message, {Map<String, dynamic>? data}) {
  return ActionSpec.log(title: 'rule_event', body: message, data: data);
}

/// -------------------- COMPOSERS (ชุดสำเร็จรูป) --------------------

/// “เตือน + ดันการ์ดเฉพาะคุณ” ใช้บ่อยมาก
List<ActionSpec> notifyAndSurfaceForYou({
  required String title,
  String? body,
  required String cardId,
  String level = 'warning', // info | warning | critical
  Map<String, dynamic>? extra,
}) {
  final notify = ActionSpec.notify(
    title: title,
    body: body,
    payload: {
      'level': level,
      if (extra != null) ...extra,
    },
  );
  final surface = surfaceForYouCard(cardId, extra: extra);
  return [notify, surface];
}

/// เตือนแล้วพาไปหน้าเป้าหมายทันที (เช่น พอเจอ HR สูงให้เปิดหน้า wearables)
List<ActionSpec> notifyAndOpen({
  required String title,
  String? body,
  required String route,
  String level = 'warning',
  Map<String, dynamic>? args,
  Map<String, dynamic>? extra,
}) {
  return [
    ActionSpec.notify(
      title: title,
      body: body,
      payload: {'level': level, if (extra != null) ...extra},
    ),
    ActionSpec.openRoute(route: route, args: args),
  ];
}
