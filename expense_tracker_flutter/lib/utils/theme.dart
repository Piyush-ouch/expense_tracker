import 'package:flutter/material.dart';

class AppTheme {
  // Colors matching web app dark theme
  static const Color backgroundColor = Color(0xFF000000); // Black background
  static const Color surfaceColor = Color(0xFF111827); // Dark gray surface
  static const Color cardColor = Color(0xFF1F2937); // Lighter dark gray for cards
  static const Color accentColor = Color(0xFFFDD835); // Yellow accent
  static const Color primaryColor = accentColor; // Alias for compatibility
  static const Color textPrimary = Color(0xFFFFFFFF); // White text
  static const Color textSecondary = Color(0xFF9CA3AF); // Gray text
  static const Color borderColor = Color(0xFF374151); // Border color
  
  // Transaction colors
  static const Color incomeColor = Color(0xFFFDD835); // Yellow for income
  static const Color expenseColor = Color(0xFFFFFFFF); // White for expense
  
  // Category icon colors (matching web app)
  static const Color iconFood = Color(0xFFA7F3D0);
  static const Color iconShopping = Color(0xFFFDE68A);
  static const Color iconTransport = Color(0xFFBFDBFE);
  static const Color iconEntertainment = Color(0xFFFBCFE8);
  static const Color iconOther = Color(0xFFE5E7EB);
  static const Color iconIncome = Color(0xFFFDD835);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: accentColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: accentColor,
      secondary: accentColor,
      surface: surfaceColor,
      background: backgroundColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: surfaceColor,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textSecondary),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: cardColor,
      selectedItemColor: accentColor,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textPrimary),
      bodySmall: TextStyle(color: textSecondary),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: textPrimary),
      titleSmall: TextStyle(color: textSecondary),
    ),
  );
}

