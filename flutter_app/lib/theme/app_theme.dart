import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A1A2E);
  static const Color accentColor = Color(0xFF2568BB);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFE65100);
  static const Color pendingColor = Color(0xFF9E9E9E);
  static const Color inProgressColor = Color(0xFF1565C0);
  static const Color cardBg = Color(0xFFF8F9FA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
      ),
      fontFamily: 'NotoSansSC',
    );
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'completed':
        return successColor;
      case 'in_progress':
        return inProgressColor;
      default:
        return pendingColor;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'completed':
        return '✅ 已完成';
      case 'in_progress':
        return '🔄 进行中';
      default:
        return '⏳ 待办';
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.sync;
      default:
        return Icons.radio_button_unchecked;
    }
  }
}
