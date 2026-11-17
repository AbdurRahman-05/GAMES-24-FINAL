import 'package:flutter/material.dart';

/// Ultra-Premium Black & Gamez24 Official Neon-Lime Palette for Player App.
class AppColors {
  AppColors._();

  // Primary Palette - Gamez24 Official Logo Neon Lime
  static const Color primary = Color(0xFFD4FF00); // Official Logo Neon Lime
  static const Color primaryLight = Color(0xFFE2FF4D); // Soft Neon Lime Tint
  static const Color primaryDark = Color(0xFFA6C900); // Deep Neon Lime

  // Secondary & Accents
  static const Color secondary = Color(0xFFFF6B00); // Energetic Electric Orange
  static const Color accent = Color(0xFFD4FF00); // Logo Lime Accent
  static const Color success = Color(0xFF10B981); // Emerald Green Indicator
  static const Color warning = Color(0xFFF59E0B); // Warm Amber
  static const Color error = Color(0xFFEF4444); // Crimson Red
  static const Color info = Color(0xFF38BDF8); // Sky Blue

  // Ultra-Deep Pitch Black Backgrounds
  static const Color backgroundLight = Color(0xFF080808); // Switched from white to pitch black
  static const Color backgroundDark = Color(0xFF050505); // Cinematic pitch black

  // Surface & Card Colors (Deep Graphite & Slate)
  static const Color cardLight = Color(0xFF141414); // Dark elevated card surface
  static const Color cardDark = Color(0xFF121212); // Deep stadium card surface
  static const Color cardElevated = Color(0xFF1A1A1A); // Modal / Dialog elevated surface

  // Text Colors (High Contrast on Black Background)
  static const Color textPrimaryLight = Color(0xFFFFFFFF); // Pure White Primary
  static const Color textSecondaryLight = Color(0xFFA1A1AA); // Cool Silver Slate
  static const Color textTertiaryLight = Color(0xFF71717A); // Muted Dark Slate
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);

  // Border & Divider (Clean Dark Graphite)
  static const Color borderLight = Color(0xFF262626); // Clean dark border
  static const Color borderDark = Color(0xFF262626);
  static const Color borderFocused = Color(0xFFD4FF00); // Neon Lime Active Border

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD4FF00), Color(0xFFAEEA00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF050505), Color(0xFF141414), Color(0xFF1A1A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF181818), Color(0xFF0F0F0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient neonGlowGradient = LinearGradient(
    colors: [Color(0xFFD4FF00), Color(0x00D4FF00)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
