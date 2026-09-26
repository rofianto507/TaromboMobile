import 'package:flutter/material.dart';

class AppTheme {
  // Palet hijau-cokelat tanah — kesan tarombo/silsilah, hangat & tradisional.
  static const Color primaryColor = Color(0xFF2E5339); // hijau tua daun
  static const Color accentColor  = Color(0xFFC8A24A); // emas/tembaga (ukiran gorga)
  static const Color errorColor   = Color(0xFFB3261E);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5EF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );
}
