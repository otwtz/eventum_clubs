import 'package:flutter/material.dart';

/// Цветовая гамма приложения. Изменение значений здесь применяется ко всей теме.
class AppColors {
  AppColors._();

  // --- Светлая тема ---
  static const Color lightPrimary = Color(0xFFE10600);
  static const Color lightSecondary = Color(0xFFFF2D2D);
  static const Color lightTertiary = Color(0xFFFF6B6B);
  static const Color lightSurface = Colors.white;
  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightOnPrimary = Colors.white;
  static const Color lightOnSecondary = Colors.white;
  static const Color lightOnSurface = Color(0xFF212121);
  static const Color lightAppBarBg = Colors.white;
  static const Color lightNavSelected = Color(0xFFE10600);
  static const Color lightNavUnselected = Colors.grey;
  static const Color lightCardBg = Colors.white;
  static const Color lightScaffoldBg = Colors.white;

  // --- Тёмная тема ---
  static const Color darkPrimary = Color(0xFFB71C1C);
  static const Color darkSecondary = Color(0xFF8B0000);
  static const Color darkTertiary = Color(0xFF7F1D1D);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkError = Color(0xFFCF6679);
  static const Color darkOnPrimary = Colors.white;
  static const Color darkOnSecondary = Colors.white;
  static const Color darkOnSurface = Colors.white;
  static const Color darkAppBarBg = Color(0xFF1E1E1E);
  static const Color darkNavSelected = Color(0xFF64B5F6);
  static const Color darkNavUnselected = Colors.grey;
  static const Color darkCardBg = Color(0xFF1E1E1E);
  static const Color darkScaffoldBg = Color(0xFF121212);
}
