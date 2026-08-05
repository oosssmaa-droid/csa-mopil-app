import 'package:flutter/material.dart';

class AppColors {
  // Dark palette (default)
  static const bg = Color(0xFF0B1B33);
  static const bg2 = Color(0xFF0F2447);
  static const card = Color(0xFF132A52);
  static const card2 = Color(0xFF16305E);
  static const accent = Color(0xFF3AA0FF);
  static const accent2 = Color(0xFF22D3A6);
  static const danger = Color(0xFFFF5A6E);
  static const warn = Color(0xFFFFB020);
  static const text = Color(0xFFEAF1FF);
  static const muted = Color(0xFF8FA3C7);
  static const border = Color(0xFF20386A);

  // Light palette
  static const lightBg = Color(0xFFF3F6FC);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCard2 = Color(0xFFF1F4FA);
  static const lightAccent = Color(0xFF2668D9);
  static const lightAccent2 = Color(0xFF0E9E79);
  static const lightDanger = Color(0xFFD9364C);
  static const lightWarn = Color(0xFFB9740A);
  static const lightText = Color(0xFF0B1B33);
  static const lightMuted = Color(0xFF5B6B8C);
  static const lightBorder = Color(0xFFDCE3F0);
}

/// Resolves theme-aware colors at call sites that can't reach Theme.of()
/// conveniently (kept simple for this capstone app instead of a full
/// ThemeExtension). Screens call AppColors.of(context).accent, etc.
class CSAColors {
  final bool isDark;
  const CSAColors(this.isDark);
  Color get bg => isDark ? AppColors.bg : AppColors.lightBg;
  Color get card => isDark ? AppColors.card : AppColors.lightCard;
  Color get card2 => isDark ? AppColors.card2 : AppColors.lightCard2;
  Color get accent => isDark ? AppColors.accent : AppColors.lightAccent;
  Color get accent2 => isDark ? AppColors.accent2 : AppColors.lightAccent2;
  Color get danger => isDark ? AppColors.danger : AppColors.lightDanger;
  Color get warn => isDark ? AppColors.warn : AppColors.lightWarn;
  Color get text => isDark ? AppColors.text : AppColors.lightText;
  Color get muted => isDark ? AppColors.muted : AppColors.lightMuted;
  Color get border => isDark ? AppColors.border : AppColors.lightBorder;
}

CSAColors csaColors(BuildContext context) =>
    CSAColors(Theme.of(context).brightness == Brightness.dark);

ThemeData buildAppTheme(bool dark) {
  final bg = dark ? AppColors.bg : AppColors.lightBg;
  final card = dark ? AppColors.card : AppColors.lightCard;
  final card2 = dark ? AppColors.card2 : AppColors.lightCard2;
  final accent = dark ? AppColors.accent : AppColors.lightAccent;
  final accent2 = dark ? AppColors.accent2 : AppColors.lightAccent2;
  final danger = dark ? AppColors.danger : AppColors.lightDanger;
  final text = dark ? AppColors.text : AppColors.lightText;
  final border = dark ? AppColors.border : AppColors.lightBorder;

  return ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bg,
    primaryColor: accent,
    colorScheme: ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: accent,
      onPrimary: dark ? const Color(0xFF04101F) : Colors.white,
      secondary: accent2,
      onSecondary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: card,
      onSurface: text,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: dark ? const Color(0xFF04101F) : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: text),
      bodyLarge: TextStyle(color: text),
    ),
  );
}

/// Shared top-bar controls (dark/light toggle, language toggle, optional
/// logout) reused across every screen's AppBar so behaviour stays
/// consistent throughout the app.
List<Widget> csaTopActions(
  BuildContext context, {
  required VoidCallback onToggleTheme,
  required VoidCallback onToggleLang,
  required bool isAr,
  VoidCallback? onLogout,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return [
    IconButton(
      icon: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          size: 20),
      onPressed: onToggleTheme,
    ),
    TextButton(
      onPressed: onToggleLang,
      child: Text(isAr ? 'EN' : 'AR'),
    ),
    if (onLogout != null)
      IconButton(
        icon: const Icon(Icons.logout, size: 20),
        onPressed: onLogout,
      ),
    const SizedBox(width: 4),
  ];
}
