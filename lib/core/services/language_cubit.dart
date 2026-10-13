import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/services/language_service.dart';
import 'package:school_management_system/core/services/translation_service.dart';

/// 📁 إدارة حالة اللغة
class LanguageCubit extends Cubit<Locale> {
  final LanguageService _languageService;

  LanguageCubit({LanguageService? languageService})
    : _languageService = languageService ?? LanguageService.instance,
      super(const Locale('ar')) {
    _loadLanguage();
  }

  /// تحميل اللغة المحفوظة + ترجمتها
  Future<void> _loadLanguage() async {
    final saved = await _languageService.getLocale();
    await TranslationService.instance.loadTranslations(saved.languageCode);
    emit(saved);
  }

  /// تغيير اللغة
  Future<void> changeLocale(Locale locale) async {
    // ✅ تحميل الترجمة الجديدة أولاً
    await TranslationService.instance.loadTranslations(locale.languageCode);
    // حفظ التفضيل
    await _languageService.saveLocale(locale);
    // إطلاق الحالة الجديدة
    emit(locale);
  }

  Future<void> changeToArabic() => changeLocale(const Locale('ar'));
  Future<void> changeToEnglish() => changeLocale(const Locale('en'));
  Future<void> changeToFrench() => changeLocale(const Locale('fr'));
}
