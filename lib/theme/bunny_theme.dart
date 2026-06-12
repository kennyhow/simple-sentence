import 'package:flutter/material.dart';

/// The bunny theme — pastel pink, rounded, fluffy.
class BunnyTheme {
  static const Color pink50 = Color(0xFFFFF0F5);   // lavender blush
  static const Color pink100 = Color(0xFFFFE4EC);  // misty rose
  static const Color pink200 = Color(0xFFFFD6E0);
  static const Color pink300 = Color(0xFFFFB6C1);  // light pink
  static const Color pink400 = Color(0xFFFF8FAB);
  static const Color pink500 = Color(0xFFE8A0BF);  // main accent
  static const Color pink600 = Color(0xFFD488A8);
  static const Color pink700 = Color(0xFFBF7090);
  static const Color brown = Color(0xFF4A3728);    // text + eyes
  static const Color cream = Color(0xFFFFF8F0);    // card bg
  static const Color lavender = Color(0xFFF0E6FF); // accent bg

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: pink500,
        brightness: Brightness.light,
        primary: pink500,
        onPrimary: brown,
        secondary: pink300,
        onSecondary: brown,
        surface: cream,
        onSurface: brown,
        primaryContainer: pink100,
        onPrimaryContainer: brown,
        secondaryContainer: lavender,
        onSecondaryContainer: brown,
      ),
      scaffoldBackgroundColor: pink50,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: pink100,
        foregroundColor: brown,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: pink300.withAlpha(80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: pink200, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: pink300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: pink200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: pink500, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: pink500,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pink500,
          side: const BorderSide(color: pink500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: pink100,
        labelStyle: const TextStyle(color: brown, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: pink200),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return pink500;
          return pink200;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return pink500;
          return pink300;
        }),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: pink300),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: pink200,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: pink500,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: pink500,
        brightness: Brightness.dark,
        primary: pink300,
        onPrimary: brown,
        secondary: pink400,
        onSecondary: brown,
        surface: const Color(0xFF2A1F2E),
        onSurface: pink100,
        primaryContainer: const Color(0xFF3D2A40),
        onPrimaryContainer: pink100,
        secondaryContainer: const Color(0xFF2D2035),
        onSecondaryContainer: pink200,
      ),
      scaffoldBackgroundColor: const Color(0xFF1A121E),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF2A1F2E),
        foregroundColor: Color(0xFFFFE4EC),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2A1F2E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF3D2A40), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A1F2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3D2A40)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3D2A40)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFB6C1), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: pink400,
          foregroundColor: brown,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pink300,
          side: const BorderSide(color: pink300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF3D2A40),
        labelStyle: const TextStyle(color: Color(0xFFFFE4EC), fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF5D3A60)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return pink400;
          return const Color(0xFF3D2A40);
        }),
        checkColor: WidgetStateProperty.all(brown),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return pink400;
          return const Color(0xFF5D3A60);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3D2A40),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF3D2A40),
        contentTextStyle: const TextStyle(color: Color(0xFFFFE4EC)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
