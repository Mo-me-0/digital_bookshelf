import 'package:flutter/material.dart';

// Define custom theme
class AppTheme {
  // Warm wood/library palette
  static const Color primary = Color(0xFF5C3D2E);
  static const Color primaryLight = Color(0xFF8B5E3C);
  static const Color accent = Color(0xFFD4A853); // for buttons
  static const Color background = Color(0xFFF5EFE6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFDF6EC); // for document card
  
  // Text colors
  static const Color textPrimary = Color(0xFF2C1810);
  static const Color textSecondary = Color(0xFF7A5C4A);
  static const Color divider = Color(0xFFE8D5C0);
  static const Color error = Color(0xFFB00020);

  // Category spine colors (assigned by user selection)
  static const List<Color> shelfColors = [
    Color(0xFF8B2635),
    Color(0xFF1B4F72),
    Color(0xFF1E6B3C),
    Color(0xFF6B4C9A),
    Color(0xFF8B6914),
    Color(0xFF2E6B6B),
    Color(0xFFB5451B),
    Color(0xFF4A4A8A),
  ];

  // Custome theme data
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          surface: background,
        ),
        
        // Scaffold
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        
        // Card style
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)
          ),
        ),
        
        // Floating action buttons
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
          labelSmall: TextStyle(color: textSecondary, fontSize: 11),
        ),
        
        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: primaryLight, 
              width: 2
            ),
          ),
        ),
      );
}
