import 'package:flutter/material.dart';

/// DineQR Color Palette — Luxury Black + Gold
class AppColors {
  AppColors._();

  // Primary
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceLight = Color(0xFF1E1E1E);
  static const Color card = Color(0xFF1A1A1A);

  // Accent
  static const Color gold = Color(0xFFF4C430);
  static const Color goldLight = Color(0xFFFFD966);
  static const Color goldDark = Color(0xFFD4A017);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF6E6E6E);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF42A5F5);

  // Order Status Colors
  static const Color pending = Color(0xFFFF9800);
  static const Color cooking = Color(0xFFE53935);
  static const Color ready = Color(0xFF4CAF50);
  static const Color served = Color(0xFF42A5F5);

  // Glassmorphism
  static const Color glassBg = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
