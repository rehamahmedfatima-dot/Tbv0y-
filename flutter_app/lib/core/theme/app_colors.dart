import 'package:flutter/material.dart';

/// TBVOY design tokens — single source of truth for color.
/// Do not hardcode hex values elsewhere in the app; reference these.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color accent = Color(0xFFF59E0B);

  // Light theme surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color divider = Color(0xFFE2E8F0);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF97316);
  static const Color danger = Color(0xFFEF4444);

  // Dark theme — elegant charcoal
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF161E2E);
  static const Color darkSurfaceElevated = Color(0xFF1E2739);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkDivider = Color(0xFF2A3446);

  // Gradients (used for hero cards, growth tree, streak flames)
  static const List<Color> primaryGradient = [Color(0xFF2563EB), Color(0xFF14B8A6)];
  static const List<Color> accentGradient = [Color(0xFFF59E0B), Color(0xFFEF4444)];
  static const List<Color> successGradient = [Color(0xFF22C55E), Color(0xFF14B8A6)];

  // Glassmorphism
  static Color glassFillLight = Colors.white.withValues(alpha: 0.55);
  static Color glassFillDark = Colors.white.withValues(alpha: 0.08);
  static Color glassBorderLight = Colors.white.withValues(alpha: 0.35);
  static Color glassBorderDark = Colors.white.withValues(alpha: 0.12);
}
