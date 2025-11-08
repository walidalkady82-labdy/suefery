import 'package:flutter/material.dart';
import 'package:suefery/core/utils/app_typography.dart';

// Define the "Ocean Blue" theme
ThemeData oceanBlueTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF4FC3F7), // Light Blue
  scaffoldBackgroundColor: const Color(0xFFF0F4F8), // A very light blue-grey
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
  ).copyWith(
    secondary: const Color(0xFFFFB74D), // Amber accent
    background: const Color(0xFFF0F4F8),
    surface: Colors.white,
    error: Colors.red.shade700,
  ),
  useMaterial3: true,
  textTheme: AppTypography.textTheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF4FC3F7),
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4FC3F7),
      foregroundColor: Colors.white,
      textStyle: AppTypography.textTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF4FC3F7),
      side: const BorderSide(color: Color(0xFF4FC3F7), width: 2),
      textStyle: AppTypography.textTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF4FC3F7),
      textStyle: AppTypography.textTheme.labelLarge,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade200,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.0),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  ),
);

// Define the "Sunset Orange" theme
ThemeData sunsetOrangeTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFFFF7043), // Deep Orange
  scaffoldBackgroundColor: const Color(0xFFFFF3E0), // A very light orange
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.orange,
    brightness: Brightness.light,
  ).copyWith(
    secondary: const Color(0xFF81D4FA), // Light Blue accent
    background: const Color(0xFFFFF3E0),
    surface: Colors.white,
    error: Colors.red.shade700,
  ),
  useMaterial3: true,
  textTheme: AppTypography.textTheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFF7043),
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFF7043),
      foregroundColor: Colors.white,
      textStyle: AppTypography.textTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFFF7043),
      side: const BorderSide(color: Color(0xFFFF7043), width: 2),
      textStyle: AppTypography.textTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFFF7043),
      textStyle: AppTypography.textTheme.labelLarge,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade200,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.0),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  ),
);