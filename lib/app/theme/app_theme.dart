import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy = Color(0xFF0B1F3A);
  static const blue = Color(0xFF1677FF);
  static const success = Color(0xFF159455);
  static const warning = Color(0xFFF3A712);
  static const error = Color(0xFFD92D20);
  static const canvas = Color(0xFFF5F7FB);
}

ThemeData buildTheme(Brightness brightness) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        brightness: brightness,
      ).copyWith(
        primary: brightness == Brightness.light
            ? AppColors.navy
            : const Color(0xFF8CB8FF),
        secondary: AppColors.blue,
        error: AppColors.error,
        surface: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF142238),
      );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: brightness == Brightness.light
        ? AppColors.canvas
        : const Color(0xFF091525),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      indicatorColor: scheme.secondaryContainer,
      backgroundColor: scheme.surface,
    ),
  );
}
