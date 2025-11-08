import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'ui/auth/login_register_screen.dart';
import 'ui/wearables/wearables_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'access_token');
  runApp(ChatMDApp(initialRoute: token == null ? '/auth' : '/wearables'));
}

class ChatMDApp extends StatelessWidget {
  const ChatMDApp({super.key, required this.initialRoute});
  final String initialRoute;

  static const apiBase = String.fromEnvironment(
    'API_BASE', defaultValue: 'https://api.chatdm.org',
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatMD',
      theme: ThemeData(
        useMaterial3: true,
        // โทนสว่าง คลีน สไตล์การแพทย์
        colorSchemeSeed: const Color(0xFF7B61FF),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F8FB),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.w700),
          bodyMedium: TextStyle(height: 1.3),
        ),
        cardTheme: CardThemeData(            // 👈 เปลี่ยนตรงนี้
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
          color: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F2F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/auth': (_) => LoginRegisterScreen(apiBase: apiBase),
        '/wearables': (_) => const WearablesScreen(),
      },
    );
  }
}
