import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Neutral base — oklch(1 0 0) / oklch(0.145 0 0) / oklch(0.205 0 0) etc.
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF0A0A0A);
  static const neutral900 = Color(0xFF171717);
  static const neutral500 = Color(0xFF737373);
  static const neutral200 = Color(0xFFE5E5E5);
  static const neutral100 = Color(0xFFF5F5F5);

  // Login/onboarding dark treatment — Tailwind slate/lime/indigo.
  static const slate950 = Color(0xFF020617);
  static const slate900 = Color(0xFF0F172A);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate50 = Color(0xFFF8FAFC);
  static const lime500 = Color(0xFF84CC16);
  static const lime400 = Color(0xFFA3E635);
  static const indigo500 = Color(0xFF6366F1);
  static const red500 = Color(0xFFEF4444);
  static const red400 = Color(0xFFF87171);

  // Beauty & Salon vertical accent — approximates oklch(0.65 0.24 5) etc.
  static const beautyPrimary = Color(0xFFF0426B);
  static const beautyAccent = Color(0xFFFDF0F2);
  static const beautyAccentForeground = Color(0xFFB23A56);
}

// Overrides Android's Material 3 default (ZoomPageTransitionsBuilder, which
// animates the incoming page via Transform.scale) with the same slide-based
// builder Cupertino uses on every platform. Repeatedly reproduced RenderBox
// "hasSize" crashes traced back to a `Transform` ancestor on screens whose
// content resizes asynchronously mid-push (service_detail_screen.dart's
// media gallery) — a known class of conflict between ZoomPageTransitionsBuilder
// and dynamically-sized content. FractionalTranslation-based slide
// transitions don't hit it. Shared by both themes below so switching Beauty
// Mode on/off never silently reintroduces the bug.
const _pageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
);

// Applied to every showModalBottomSheet() call in the app automatically
// (Flutter reads this from Theme.of(context) whenever a call site doesn't
// pass its own `shape:`) — rounded top corners without having to touch each
// of the ~6 bottom-sheet call sites individually.
final _bottomSheetTheme = BottomSheetThemeData(
  backgroundColor: AppColors.white,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  showDragHandle: true,
);

class AppTheme {
  AppTheme._();

  // The default app-wide theme (Home, Browse, Detail, Profile...) — neutral
  // black/white, matching the admin dashboard's non-login shadcn theme.
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.black,
        brightness: Brightness.light,
        primary: AppColors.black,
        onPrimary: AppColors.white,
        surface: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      pageTransitionsTheme: _pageTransitionsTheme,
      bottomSheetTheme: _bottomSheetTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  // "Beauty Mode" — the mobile counterpart of citycalls-admin-web's existing
  // pink Beauty & Salon toggle (useBeautyMode.ts). Same structural shape as
  // light() so anything relying on default component theming (AppBar,
  // FilledButton, input fields — which is most of the app, screens were
  // deliberately built without inline color overrides on buttons for
  // exactly this reason) re-colors automatically on toggle; only a handful
  // of screens with custom-painted brand chrome (Home dashboard's header)
  // need their own explicit Beauty Mode branch.
  static ThemeData beauty() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.beautyPrimary,
        brightness: Brightness.light,
        primary: AppColors.beautyPrimary,
        onPrimary: AppColors.white,
        surface: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.beautyPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      pageTransitionsTheme: _pageTransitionsTheme,
      bottomSheetTheme: _bottomSheetTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.beautyPrimary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.beautyAccent,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
