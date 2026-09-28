import 'package:flutter/material.dart';

/// Premium Warm Cream & Terracotta Design Palette for Games24 Owner.
class AppColors {
  AppColors._();

  // Primary Palette (Deep Emerald & Cobalt)
  static const Color primary = Color(0xFF154D36); // Deep Botanical Emerald
  static const Color primaryLight = Color(0xFF2D7A5B);
  static const Color primaryDark = Color(0xFF0C3323);

  // Secondary & Accents (Warm Terracotta & Sunburst)
  static const Color secondary = Color(0xFFD96B43); // Warm Terracotta Rust
  static const Color accent = Color(0xFFEAB308); // Warm Gold
  static const Color success = Color(0xFF16A34A); // Forest Green
  static const Color warning = Color(0xFFEA580C); // Warm Amber
  static const Color error = Color(0xFFDC2626); // Crimson Red

  // Warm Cream Background Colors
  static const Color backgroundLight = Color(0xFFFFFFFF); // Pure White Background
  static const Color backgroundDark = Color(0xFF121916); // Deep Forest Charcoal

  // Surface & Card Colors
  static const Color cardLight = Color(0xFFFFFFFF); // Warm White Card
  static const Color cardDark = Color(0xFF1C2622); // Dark Forest Card

  // Text Colors (Warm Charcoal & Stone)
  static const Color textPrimaryLight = Color(0xFF1C1917); // Deep Stone Charcoal
  static const Color textSecondaryLight = Color(0xFF78716C); // Warm Muted Slate
  static const Color textPrimaryDark = Color(0xFFFAF6EE);
  static const Color textSecondaryDark = Color(0xFFA8A29E);

  // Border & Divider (Linen Tone)
  static const Color borderLight = Color(0xFFE5E7EB); // Clean Light Grey Border
  static const Color borderDark = Color(0xFF2C3933);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF154D36), Color(0xFF2D7A5B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0C3323), Color(0xFF154D36), Color(0xFFD96B43)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1C2622), Color(0xFF121916)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
