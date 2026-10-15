import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/services/theme_service.dart';

/// 📁 إدارة حالة الثيم
///
/// - تُحمّل الثيم المحفوظ عند البدء
/// - تدعم: فاتح / داكن / حسب النظام
/// - تُوفّر `ThemeMode` لـ `MaterialApp`
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({ThemeService? themeService})
      : _themeService = themeService ?? ThemeService.instance,
        super(_defaultMode) {
    _loadSavedTheme();
  }

  /// الوضع الافتراضي
  static const ThemeMode _defaultMode = ThemeMode.system;

  final ThemeService _themeService;

  // ============================================
  // Getters
  // ============================================

  /// الوضع الحالي
  ThemeMode get currentThemeMode => state;

  /// هل الوضع الحالي داكن؟
  bool get isDarkMode => state == ThemeMode.dark;

  /// هل الوضع الحالي فاتح؟
  bool get isLightMode => state == ThemeMode.light;

  /// هل الوضع يتبع النظام؟
  bool get isSystemMode => state == ThemeMode.system;

  // ============================================
  // التحميل
  // ============================================

  /// تحميل الثيم المحفوظ
  Future<void> _loadSavedTheme() async {
    try {
      final ThemeMode saved = await _themeService.getThemeMode();
      if (isClosed) return;
      emit(saved);
    } catch (error) {
      _log('🔴 خطأ في تحميل الثيم: $error');
      if (isClosed) return;
      emit(_defaultMode);
    }
  }

  // ============================================
  // تغيير الثيم
  // ============================================

  /// تغيير وضع الثيم
  Future<void> setThemeMode(ThemeMode mode) async {
    // نفس الوضع؟ لا حاجة لعملية كتابة على القرص
    if (state == mode) {
      return;
    }

    try {
      await _themeService.saveThemeMode(mode);
      if (isClosed) return;
      emit(mode);
      _log('✅ تم تغيير الثيم إلى: $mode');
    } catch (error) {
      _log('🔴 خطأ في تغيير الثيم: $error');
    }
  }

  /// الوضع الفاتح
  Future<void> setLightTheme() => setThemeMode(ThemeMode.light);

  /// الوضع الداكن
  Future<void> setDarkTheme() => setThemeMode(ThemeMode.dark);

  /// حسب النظام
  Future<void> setSystemTheme() => setThemeMode(ThemeMode.system);

  /// تبديل ذكي للثيم
  ///
  /// - من `dark` ← `light` والعكس
  /// - من `system` ← **عكس وضع النظام الفعلي** (وإلا بدا الزر بلا أثر)
  Future<void> toggleTheme({Brightness? systemBrightness}) async {
    final ThemeMode next = switch (state) {
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.system => systemBrightness == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark,
    };
    await setThemeMode(next);
  }

  /// تبديل من داخل الواجهة — يحسب وضع النظام تلقائيًا
  ///
  /// استخدمها في الأزرار: `context.read<ThemeCubit>().toggleThemeFrom(context)`
  Future<void> toggleThemeFrom(BuildContext context) {
    return toggleTheme(
      systemBrightness: MediaQuery.platformBrightnessOf(context),
    );
  }

  // ============================================
  // دوال مساعدة
  // ============================================

  /// طباعة في وضع التطوير فقط
  void _log(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }
}
