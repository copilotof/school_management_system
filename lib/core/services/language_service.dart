import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📁 خدمة إدارة اللغة
/// تحفظ وتسترجع لغة التطبيق

class LanguageService {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static const String _languageKey = 'app_language';

  /// الحصول على اللغة المحفوظة
  Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languageKey);
    return switch (saved) {
      'en' => const Locale('en'),
      'fr' => const Locale('fr'),
      _ => const Locale('ar'), // الافتراضية: العربية
    };
  }

  /// حفظ اللغة
  Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }

  /// تغيير اللغة
  Future<Locale> changeLocale(Locale newLocale) async {
    await saveLocale(newLocale);
    return newLocale;
  }
}
