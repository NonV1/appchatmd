// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

/// ======================
/// Design Tokens
/// ======================
@immutable
class AppTokens {
  const AppTokens({
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.bg,
    required this.surface,
    required this.onSurface,
    required this.success,
    required this.warning,
    required this.danger,
    required this.radius,
    required this.spacing,
    required this.elevation,
    required this.glassOpacity,
    required this.glassBorder,
  });

  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;

  final Color bg;
  final Color surface;
  final Color onSurface;

  final Color success;
  final Color warning;
  final Color danger;

  final BorderRadius radius;
  final EdgeInsets spacing;
  final double elevation;

  final double glassOpacity;
  final Color glassBorder;
}

const _lightTokens = AppTokens(
  primary: Color(0xFF7B61FF),
  primaryContainer: Color(0xFFE9E3FF),
  onPrimary: Colors.white,
  bg: Color(0xFFF7F7FB),
  surface: Colors.white,
  onSurface: Color(0xFF0E1321),
  success: Color(0xFF2EBD85),
  warning: Color(0xFFF1A538),
  danger: Color(0xFFE9605A),
  radius: BorderRadius.all(Radius.circular(18)),
  spacing: EdgeInsets.all(16),
  elevation: 0.8,
  glassOpacity: 0.65,
  glassBorder: Color(0x33FFFFFF),
);

const _darkTokens = AppTokens(
  primary: Color(0xFF8F7AFF),
  primaryContainer: Color(0xFF2A2547),
  onPrimary: Colors.white,
  bg: Color(0xFF0B0C12),
  surface: Color(0xFF141624),
  onSurface: Color(0xFFE8EAF3),
  success: Color(0xFF3DD598),
  warning: Color(0xFFF5B449),
  danger: Color(0xFFF97066),
  radius: BorderRadius.all(Radius.circular(18)),
  spacing: EdgeInsets.all(16),
  elevation: 0.6,
  glassOpacity: 0.50,
  glassBorder: Color(0x26FFFFFF),
);

/// ======================
/// Helpers: เอา Tokens จาก Context ได้เร็ว ๆ
/// ======================
class AppTheme {
  static const AppSpacing spacing = AppSpacing();
  static const Color pageBg = Color(0xFFF7F7FB);

  static AppTokens tokensOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkTokens
          : _lightTokens;

  static ThemeData light({bool lowSpec = false, bool reduceMotion = false}) {
    final t = _lightTokens;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: t.primary,
        onPrimary: t.onPrimary,
        secondary: t.primaryContainer,
        onSecondary: t.onSurface,
        error: t.danger,
        onError: Colors.white,
        surface: t.surface,
        onSurface: t.onSurface,
      ),
      scaffoldBackgroundColor: t.bg,
      textTheme: _buildTextTheme(Brightness.light, t, lowSpec),
      cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: t.bg,
        foregroundColor: t.onSurface,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface.withOpacity(0.7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: t.radius,
          borderSide: BorderSide(color: t.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: t.radius,
          borderSide: BorderSide(color: t.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: t.radius,
          borderSide: BorderSide(color: t.primary, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: t.primary,
          foregroundColor: t.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: t.radius),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: t.radius),
          side: BorderSide(color: t.glassBorder),
          foregroundColor: t.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      iconTheme: IconThemeData(color: t.onSurface.withOpacity(0.85)),
      dividerColor: t.glassBorder,
      splashFactory: reduceMotion ? NoSplash.splashFactory : null,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData dark({bool lowSpec = false, bool reduceMotion = false}) {
    final t = _darkTokens;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: t.primary,
        onPrimary: t.onPrimary,
        secondary: t.primaryContainer,
        onSecondary: t.onSurface,
        error: t.danger,
        onError: Colors.white,
        surface: t.surface,
        onSurface: t.onSurface,
      ),
      scaffoldBackgroundColor: t.bg,
      textTheme: _buildTextTheme(Brightness.dark, t, lowSpec),
      cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: t.bg,
        foregroundColor: t.onSurface,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface.withOpacity(0.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: t.radius,
          borderSide: BorderSide(color: t.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: t.radius,
          borderSide: BorderSide(color: t.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: t.radius,
          borderSide: BorderSide(color: t.primary, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: t.primary,
          foregroundColor: t.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: t.radius),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: t.radius),
          side: BorderSide(color: t.glassBorder),
          foregroundColor: t.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      iconTheme: IconThemeData(color: t.onSurface.withOpacity(0.88)),
      dividerColor: t.glassBorder,
      splashFactory: reduceMotion ? NoSplash.splashFactory : null,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

class AppSpacing {
  const AppSpacing();

  double get xs => 6;
  double get sm => 10;
  double get md => 14;
  double get lg => 20;
  double get xl => 28;
}
/// ======================
/// Glass helpers (ใช้ glassmorphism_ui)
/// ======================
class Glass {
  static BoxDecoration decorationLite({
    required AppTokens t,
    bool elevated = false,
  }) {
    // ใช้เป็น fallback (เมื่อปิดเบลอ) และให้โทน gradient โปร่งใส
    return BoxDecoration(
      color: t.surface.withOpacity(t.glassOpacity),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(t.glassOpacity * 0.22),
          Colors.white.withOpacity(t.glassOpacity * 0.10),
          Colors.white.withOpacity(t.glassOpacity * 0.06),
        ],
      ),
      borderRadius: t.radius,
      border: Border.all(color: t.glassBorder, width: 1),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
          : const [],
    );
  }

  /// แผงกระจกหลัก:
  /// - ถ้า useBlur=false จะเป็น Container + gradient (เบาเครื่อง)
  /// - ถ้า useBlur=true ใช้ GlassContainer จาก glassmorphism_ui
  static Widget panel({
    required AppTokens t,
    required Widget child,
    bool useBlur = false,
    double blurSigma = 12,
    bool elevated = false,
    EdgeInsets? padding,
  }) {
    final pad = padding ?? const EdgeInsets.all(16);

    // Fallback: ไม่เบลอ ประหยัด GPU
    if (!useBlur || blurSigma <= 0) {
      return Container(
        decoration: decorationLite(t: t, elevated: elevated),
        padding: pad,
        child: child,
      );
    }

    final BorderRadiusGeometry brg = t.radius;
    final BorderRadius br =
      brg is BorderRadius ? brg : BorderRadius.circular(16);

    return GlassContainer(
      blur: blurSigma,
      color: Colors.white.withOpacity(t.glassOpacity),
      borderRadius: br,                 // <-- ต้องเป็น BorderRadius
      border: Border.all(color: t.glassBorder, width: 1),
      shadowStrength: elevated ? 8 : 0,
      child: Padding(padding: pad, child: child),
    );
  }
}

/// ======================
/// Private: TextTheme
/// ======================
TextTheme _buildTextTheme(Brightness b, AppTokens t, bool lowSpec) {
  final base =
      (b == Brightness.dark ? ThemeData.dark() : ThemeData.light()).textTheme;

  const tightLs = -0.05;
  const normalLs = 0.0;

  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontSize: 44,
      fontWeight: FontWeight.w700,
      letterSpacing: tightLs,
      color: t.onSurface,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: tightLs,
      color: t.onSurface,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: tightLs,
      color: t.onSurface,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: normalLs,
      color: t.onSurface,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: normalLs,
      color: t.onSurface.withOpacity(0.92),
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: normalLs,
      color: t.onSurface.withOpacity(0.86),
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: t.onSurface.withOpacity(0.9),
    ),
  );
}
