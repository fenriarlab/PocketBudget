import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Surfaces (Calm Finance Specification v1.0)
  static const Color primary = Color(0xFF4F7FFF); // Trust Blue
  static const Color primaryLight = Color(0xFF7CA0FF);
  static const Color primaryDark = Color(0xFF355ECC);

  // Status & Health Colors
  static const Color expense = Color(0xFFFF6B6B);
  static const Color income = Color(0xFF36C98B);
  static const Color warning = Color(0xFFFFB84D);
  static const Color pressureVeryLow = Color(0xFF65C99A);
  static const Color pressureLow = Color(0xFFA8D96D);
  static const Color pressureMedium = Color(0xFFF3B34C);
  static const Color pressureHigh = Color(0xFFE96A68);
  static const Color pressureVeryHigh = Color(0xFF9C65D6);

  // Backgrounds & Surface (Dark Theme First)
  static const Color darkBackground = Color(0xFF111214); // Primary Background
  static const Color darkSurface = Color(0xFF191C22);    // Surface Cards & Lists
  static const Color darkElevated = Color(0xFF22262E);   // Modals & Bottom Sheets

  // Typography Neutrals
  static const Color lightTextPrimary = Color(0xFF263248);
  static const Color lightTextSecondary = Color(0xFF758096);
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF9297A5);
  static const Color textMuted = Color(0xFF656B78);
  static const Color divider = Color(0xFF292E38);
}
