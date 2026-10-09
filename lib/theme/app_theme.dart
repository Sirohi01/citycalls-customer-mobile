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

  // Shared look for every screen built from stock Material widgets (AppBar,
  // buttons, fields, cards, dialogs…): light grey page, white bordered
  // cards, dark ink primary buttons and CityCalls green accents — the same
  // language as the redesigned Profile / Edit Profile / drawer screens.
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _green = Color(0xFF16A34A);
  static const _page = Color(0xFFF6F7F9);

  static ThemeData _build({
    required Color primary,
    required Color accent,
    required Color fieldFocus,
  }) {
    final radius12 = BorderRadius.circular(12);
    OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: radius12, borderSide: BorderSide(color: c, width: w));
    WidgetStateProperty<Color?> selected(Color on) =>
        WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? on : null);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _page,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        onPrimary: AppColors.white,
        secondary: accent,
        surface: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: _ink,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleSpacing: 4,
        titleTextStyle: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: _ink),
        shape: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      pageTransitionsTheme: _pageTransitionsTheme,
      bottomSheetTheme: _bottomSheetTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: _line,
          disabledForegroundColor: const Color(0xFF94A3B8),
          minimumSize: const Size.fromHeight(50),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: radius12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          textStyle:
              const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: radius12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: _line),
          textStyle:
              const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: radius12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        labelStyle: const TextStyle(color: _muted),
        floatingLabelStyle: TextStyle(color: fieldFocus),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        border: field(_line),
        enabledBorder: field(_line),
        focusedBorder: field(fieldFocus, 1.5),
        errorBorder: field(const Color(0xFFDC2626)),
        focusedErrorBorder: field(const Color(0xFFDC2626), 1.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _line),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _muted,
        titleTextStyle: TextStyle(
            fontSize: 14.5, fontWeight: FontWeight.w600, color: _ink),
        subtitleTextStyle: TextStyle(fontSize: 12.5, color: _muted),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFF1F5F9)),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: accent.withValues(alpha: 0.12),
        side: const BorderSide(color: _line),
        labelStyle: const TextStyle(fontSize: 13, color: _ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: _ink),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        shape: RoundedRectangleBorder(borderRadius: radius12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      checkboxTheme: CheckboxThemeData(
        fillColor: selected(accent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(fillColor: selected(accent)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.white : null),
        trackColor: selected(accent),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: _ink,
        unselectedLabelColor: _muted,
        indicatorColor: accent,
        labelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  // The default app-wide theme.
  static ThemeData light() =>
      _build(primary: _ink, accent: _green, fieldFocus: _ink);

  // "Beauty Mode" — the mobile counterpart of citycalls-admin-web's pink
  // Beauty & Salon toggle. Same component theming as light(), recoloured, so
  // anything relying on default theming re-colours automatically on toggle.
  static ThemeData beauty() => _build(
      primary: AppColors.beautyPrimary,
      accent: AppColors.beautyPrimary,
      fieldFocus: AppColors.beautyPrimary);
}
