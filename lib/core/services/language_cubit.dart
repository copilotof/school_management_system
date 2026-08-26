import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/services/language_service.dart';

/// 📁 إدارة حالة اللغة

class LanguageCubit extends Cubit<Locale> {
  final LanguageService _languageService;

  LanguageCubit({LanguageService? languageService})
    : _languageService = languageService ?? LanguageService.instance,
      super(const Locale('ar')) {
    _loadLanguage();
  }

  /// تحميل اللغة المحفوظة
  Future<void> _loadLanguage() async {
    final saved = await _languageService.getLocale();
    emit(saved);
  }

  /// تغيير اللغة
  Future<void> changeLocale(Locale locale) async {
    await _languageService.saveLocale(locale);
    emit(locale);
  }

  /// تغيير إلى العربية
  Future<void> changeToArabic() => changeLocale(const Locale('ar'));

  /// تغيير إلى الإنجليزية
  Future<void> changeToEnglish() => changeLocale(const Locale('en'));

  /// تغيير إلى الفرنسية
  Future<void> changeToFrench() => changeLocale(const Locale('fr'));
}
