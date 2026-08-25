import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/services/theme_service.dart';

/// 📁 إدارة حالة الثيم

class ThemeCubit extends Cubit<ThemeMode> {
  final ThemeService _themeService;

  ThemeCubit({ThemeService? themeService})
    : _themeService = themeService ?? ThemeService.instance,
      super(ThemeMode.system) {
    _loadTheme();
  }

  /// تحميل الثيم المحفوظ
  Future<void> _loadTheme() async {
    final saved = await _themeService.getThemeMode();
    emit(saved);
  }

  /// تغيير الثيم
  Future<void> setThemeMode(ThemeMode mode) async {
    await _themeService.saveThemeMode(mode);
    emit(mode);
  }

  /// تبديل بين الفاتح والداكن
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }
}
