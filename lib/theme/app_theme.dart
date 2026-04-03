import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary       = Color(0xFF1E3A8A);
  static const Color primaryLight  = Color(0xFF3B5BDB);
  static const Color accent        = Color(0xFF06B6D4);
  static const Color success       = Color(0xFF10B981);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color danger        = Color(0xFFEF4444);
  static const Color purple        = Color(0xFF8B5CF6);
  static const Color bgLight       = Color(0xFFF8FAFC);
  static const Color bgCard        = Color(0xFFFFFFFF);
  static const Color bgDark        = Color(0xFF0F172A);
  static const Color bgCardDark    = Color(0xFF1E293B);
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light),
    scaffoldBackgroundColor: bgLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary, foregroundColor: Colors.white, elevation: 0, centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: bgCard, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgCard, selectedItemColor: primary, unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed, elevation: 0,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark),
    scaffoldBackgroundColor: bgDark,
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E293B), foregroundColor: Colors.white, elevation: 0, centerTitle: true),
    cardTheme: CardTheme(
      color: bgCardDark, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF334155))),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accent, width: 2)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E293B), selectedItemColor: accent,
      unselectedItemColor: Color(0xFF64748B), type: BottomNavigationBarType.fixed,
    ),
  );
}
