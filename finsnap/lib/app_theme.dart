// app_theme.dart
// Centralized design system for FinSnap
// All colors, typography, and category mappings live here

import 'package:flutter/material.dart';

class AppTheme {
  // ── Color Palette ──
  static const Color navy       = Color(0xFF0D1B2A);
  static const Color navyLight  = Color(0xFF1A3550);
  static const Color amber      = Color(0xFFF5A623);
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface    = Colors.white;
  static const Color green      = Color(0xFF2ECC71);
  static const Color red        = Color(0xFFE74C3C);
  static const Color textPrimary   = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF8A96A3);

  // ── Category Colors ──
  static Color categoryColor(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'food':          return Color(0xFFFF6B35);
      case 'transport':     return Color(0xFF4A90E2);
      case 'shopping':      return Color(0xFFE91E8C);
      case 'entertainment': return Color(0xFF9B59B6);
      case 'bills':         return Color(0xFFE74C3C);
      case 'health':        return Color(0xFF2ECC71);
      case 'salary':        return Color(0xFF1ABC9C);
      case 'freelance':     return Color(0xFF3498DB);
      case 'investment':    return Color(0xFFF39C12);
      case 'refund':        return Color(0xFF00BCD4);
      case 'gift':          return Color(0xFFFF4081);
      default:              return Color(0xFF8A96A3);
    }
  }

  // ── Category Icons ──
  static IconData categoryIcon(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'food':          return Icons.restaurant_rounded;
      case 'transport':     return Icons.directions_car_rounded;
      case 'shopping':      return Icons.shopping_bag_rounded;
      case 'entertainment': return Icons.movie_rounded;
      case 'bills':         return Icons.receipt_long_rounded;
      case 'health':        return Icons.favorite_rounded;
      case 'salary':        return Icons.work_rounded;
      case 'freelance':     return Icons.laptop_rounded;
      case 'investment':    return Icons.trending_up_rounded;
      case 'refund':        return Icons.replay_rounded;
      case 'gift':          return Icons.card_giftcard_rounded;
      default:              return Icons.category_rounded;
    }
  }

  // ── Theme ──
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.light(
      primary: navy,
      secondary: amber,
      surface: surface,
      background: background,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFE8ECF0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFE8ECF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: navy, width: 1.5),
      ),
      hintStyle: TextStyle(color: Color(0xFFB0BAC3), fontSize: 14),
      labelStyle: TextStyle(color: Color(0xFF8A96A3), fontSize: 13),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: navy,
      unselectedLabelColor: Colors.grey,
      indicatorColor: amber,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    ),
  );
}