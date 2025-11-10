// lib/main.dart
import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'core/api/http_client.dart';
import 'core/user/session.dart';
import 'core/router/app_router.dart';
import 'core/perf/frame_guard.dart';
import 'core/services/background_poll.dart';
import 'core/auth/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) ลด jank เฟรมแรกๆ
  await FrameGuard.I.warmUpShadersSafe(
    imageCacheMaxSize: 200,
    imageCacheMaxMemoryBytes: 64 << 20, // ~64MB
  );

  // 2) โหลด session
  await Session.I.hydrate();

  // 3) ตั้งค่า HTTP client กลาง
  const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://api.chatdm.org',
  );
  HttpClient.I.init(
    baseUrl: apiBase,
    getToken: Session.I.getToken,
  );

  // 4) พูลพื้นหลัง — ต้อง configure ก่อน
  BackgroundPoll.I.configure(
    fetcher: () async => <String, num>{},              // TODO: ฉีด HealthRepo จริง
    evaluator: (metrics, now, reason) async => BgDecision(),
    onNotifications: null,                             // TODO: ต่อ inbox/notifier ถ้าพร้อม
  );
  await BackgroundPoll.I.init();
  await BackgroundPoll.I.setEnabled(true, intervalMin: 10);

  // 5) GoRouter
  final auth = AuthService.I;
  final router = createAppRouter(auth: auth, session: Session.I);

  runApp(ChatMDApp(routerConfig: router));
}

class ChatMDApp extends StatelessWidget {
  const ChatMDApp({super.key, required this.routerConfig});
  final RouterConfig<Object> routerConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChatMD',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: routerConfig,
    );
  }
}
