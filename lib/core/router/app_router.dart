// lib/core/router/app_router.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_service.dart';
import '../user/session.dart';

// wearables
import '../../features/wearables/screens/unified_wearable_screen.dart';

// Auth
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';

// AI
import '../../features/ai_chat/screens/ai_chat_screen.dart';
import '../../features/ai_chat/screens/ai_disclaimer_screen.dart';

// Main pages
import '../../features/home/home_screen.dart';
import '../../ui/feed/feed_screen.dart';
import '../../ui/settings/settings_screen.dart';
import '../../features/more/screens/more_screen.dart';

// Feature detail pages (ถ้ามีไฟล์แล้ว importของจริงแทน placeholder ได้เลย)
import '../../features/food/screens/food_screen.dart';
import '../../features/fit/screens/fit_screen.dart';
// ถ้ายังไม่มีหน้าพวกนี้จริง ๆ เราจะมี placeholder ด้านล่าง

// Onboarding (ถ้ายังไม่ทำก็ปล่อยไว้ได้)
import '../../ui/onboarding/consent_screen.dart';
import '../../ui/onboarding/profile_form_screen.dart';
import '../../ui/onboarding/conditions_picker_screen.dart';
import '../../ui/onboarding/done_screen.dart';

// ---------- Placeholders (ลบทิ้งเมื่อมีหน้าจริง) ----------

class _DiseaseCheckScreen extends StatelessWidget {
  const _DiseaseCheckScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('AI Disease Check')),
    body: Center(child: Text('Disease check (placeholder)')),
  );
}

class _DoctorScreen extends StatelessWidget {
  const _DoctorScreen();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Doctor (placeholder)')));
}
// -----------------------------------------------------------

class AppRoute {
  // auth
  static const login = 'login';
  static const register = 'register';

  // main tabs
  static const home = 'home';
  static const feed = 'feed';
  static const settings = 'settings';
  static const more = 'more';

  // features (คืนชื่อเดิมให้ MoreScreen ใช้ได้)
  static const wearable = 'wearable';
  static const aiDisease = 'ai_disease';
  static const food = 'food';
  static const fit = 'fit';

  // ai chat
  static const aiChat = 'ai_chat';
  static const aiDisclaimer = 'ai_disclaimer';

  // onboarding
  static const onboardingConsent = 'onboarding_consent';
  static const onboardingProfile = 'onboarding_profile';
  static const onboardingConditions = 'onboarding_conditions';
  static const onboardingDone = 'onboarding_done';

  // misc
  static const doctor = 'doctor';
}

GoRouter createAppRouter({
  required AuthService auth,
  required Session session,
}) {
  final Listenable refreshListenable = session.listenable;
  bool isAuthed() => session.cachedToken?.isNotEmpty == true;

  return GoRouter(
    debugLogDiagnostics: kDebugMode,
    initialLocation: '/login',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authed = isAuthed();
      final loc = state.matchedLocation;
      final goingAuth = (loc == '/login' || loc == '/register');
      final isPublic = (loc == '/ai_disclaimer');

      if (!authed && !goingAuth && !isPublic) return '/login';
      if (authed && goingAuth) return '/';
      return null;
    },
    routes: [
      // --- auth ---
      GoRoute(
        name: AppRoute.login,
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: AppRoute.register,
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // --- ai ---
      GoRoute(
        name: AppRoute.aiDisclaimer,
        path: '/ai_disclaimer',
        builder: (context, state) => const AiDisclaimerScreen(),
      ),
      GoRoute(
        name: AppRoute.aiChat,
        path: '/ai_chat',
        builder: (context, state) => const AiChatScreen(),
      ),

      // --- main pages (ไม่มี ShellRoute แล้ว) ---
      GoRoute(
        name: AppRoute.home,
        path: '/',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HomeScreen()),
      ),
      GoRoute(
        name: AppRoute.feed,
        path: '/feed',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: FeedScreen()),
      ),
      GoRoute(
        name: AppRoute.settings,
        path: '/settings',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SettingsScreen()),
      ),
      GoRoute(
        name: AppRoute.more,
        path: '/more',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: MoreScreen()),
      ),

      // --- features (ให้ MoreScreen ใช้ push/go ชื่อเหล่านี้ได้) ---
      // Wearable feature uses the real screen
      GoRoute(
        name: AppRoute.aiDisease,
        path: '/ai_disease',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: _DiseaseCheckScreen()),
      ),
      GoRoute(
        name: AppRoute.food,
        path: '/food',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: FoodScreen()),
      ),
      GoRoute(
        name: AppRoute.fit,
        path: '/fit',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: FitScreen()),
      ),

            GoRoute(
        path: '/onboarding/consent',
        builder: (context, state) => const ConsentScreen(),
      ),
      GoRoute(
        path: '/onboarding/profile',
        builder: (context, state) => const ProfileFormScreen(),
      ),
      GoRoute(
        path: '/onboarding/conditions',
        builder: (context, state) => const ConditionsPickerScreen(),
      ),
      GoRoute(
        path: '/onboarding/done',
        builder: (context, state) => const DoneScreen(),
      ),
      GoRoute(
    name: AppRoute.wearable,
    path: '/wearable',
    pageBuilder: (context, state) =>
      const NoTransitionPage(child: UnifiedWearableScreen()),
      ),
      // --- misc ---
      GoRoute(
        name: AppRoute.doctor,
        path: '/doctor',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: _DoctorScreen()),
      ),
          // Quick panel (placeholder)
          GoRoute(
            path: '/quick',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Quick Panel')),
              body: const Center(child: Text('Quick panel (placeholder)')),
            ),
          ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}',
            style: const TextStyle(fontSize: 16)),
      ),
    ),
  );
}
