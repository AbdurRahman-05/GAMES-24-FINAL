import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Ultra-Premium Dark Theme with Gamez24 Official Logo Neon-Lime Accent for Player App.
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
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.black,
      elevation: 3,
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
    datePickerTheme: DatePickerThemeData(
      backgroundColor: const Color(0xFF141414),
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2E2E2E), width: 1),
      ),
      headerBackgroundColor: const Color(0xFF1A1A1A),
      headerForegroundColor: Colors.white,
      headerHeadlineStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
      headerHelpStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFFA1A1AA),
      ),
      weekdayStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFFA1A1AA),
      ),
      dayStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.black;
        }
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFF52525B);
        }
        return Colors.white;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return null;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.black;
        }
        return AppColors.primary;
      }),
      todayBorder: const BorderSide(color: AppColors.primary, width: 1.5),
      yearStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.black;
        }
        return Colors.white;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return null;
      }),
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: const Color(0xFFA1A1AA),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
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

  // lightTheme also maps to the dark pitch-black theme to keep experience cohesive
  static ThemeData lightTheme = darkTheme;
}
