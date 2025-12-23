import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode { defaultDark, amoled, light }

class AppTheme {
  static const Color background = Color(0xFF151026); // Dark Navy Purple
  static const Color amoledBackground = Color(0xFF000000); // Pitch Black
  static const Color lightBackground = Color(0xFFF8FAFC); // White/Slate

  static const Color surface = Color(0xFF1E293B);
  static const Color amoledSurface = Color(0xFF000000);
  static const Color lightSurface = Color(0xFFFFFFFF);

  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color income = Color(0xFF10B981); // Emerald
  static const Color expense = Color(0xFFEF4444); // Red
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);

  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.amoled:
        return _buildTheme(
          amoledBackground,
          amoledSurface,
          Brightness.dark,
          isAmoled: true,
        );
      case AppThemeMode.light:
        return _buildTheme(lightBackground, lightSurface, Brightness.light);
      case AppThemeMode.defaultDark:
        return _buildTheme(background, surface, Brightness.dark);
    }
  }

  static ThemeData _buildTheme(
    Color bg,
    Color surf,
    Brightness brightness, {
    bool isAmoled = false,
  }) {
    final bool isLight = brightness == Brightness.light;
    final primaryText = isLight ? lightTextPrimary : textPrimary;
    final secondaryText = isLight ? lightTextSecondary : textSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      canvasColor: bg,
      cardColor: surf,
      dividerColor: isLight
          ? Colors.black.withOpacity(0.05)
          : Colors.white.withOpacity(0.1),
      shadowColor: isLight
          ? Colors.black.withOpacity(0.1)
          : Colors.black.withOpacity(0.3),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: primary,
        onSecondary: Colors.white,
        error: expense,
        onError: Colors.white,
        surface: surf,
        onSurface: primaryText,
        surfaceContainerHighest: isLight
            ? Colors.grey.withOpacity(0.05)
            : (isAmoled ? Colors.black : Colors.white.withOpacity(0.05)),
      ),
      textTheme:
          GoogleFonts.outfitTextTheme(
            isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme,
          ).apply(
            bodyColor: primaryText,
            displayColor: primaryText,
            decorationColor: secondaryText,
          ),
      iconTheme: IconThemeData(color: isLight ? lightTextPrimary : textPrimary),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isLight
                ? Colors.black.withOpacity(0.05)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => getTheme(AppThemeMode.defaultDark);
}
