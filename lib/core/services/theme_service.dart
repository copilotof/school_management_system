import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📁 خدمة إدارة الثيم
/// تحفظ وتسترجع تفضيل المستخدم (فاتح/داكن/نظام)

class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const String _themeKey = 'theme_mode';

  /// الحصول على وضع الثيم المحفوظ
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// حفظ وضع الثيم
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  /// تبديل بين الفاتح والداكن
  Future<ThemeMode> toggleTheme(ThemeMode current) async {
    final newMode = current == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await saveThemeMode(newMode);
    return newMode;
  }
}
