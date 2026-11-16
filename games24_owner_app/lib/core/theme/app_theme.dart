import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Ultra-Premium Dark Theme with Gamez24 Official Logo Neon-Lime Accent.
class AppTheme {
  AppTheme._();

  static const double borderRadius = 20.0;

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.cardDark,
      error: AppColors.error,
      onPrimary: Colors.black, // High-contrast black on neon lime buttons
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
    ),
    textTheme: AppTypography.getTextTheme(isDark: true),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: const BorderSide(color: AppColors.borderDark, width: 1),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: const BorderSide(color: AppColors.borderDark, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF181818),
      hintStyle: const TextStyle(
        color: Color(0xFF71717A),
        fontSize: 13.5,
      ),
      labelStyle: const TextStyle(
        color: Color(0xFFA1A1AA),
        fontSize: 13.5,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
      prefixIconColor: const Color(0xFFA1A1AA),
      suffixIconColor: const Color(0xFFA1A1AA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      thickness: 1,
    ),
  );

  // lightTheme also maps to the dark pitch-black theme as requested by user
  static ThemeData lightTheme = darkTheme;
}
