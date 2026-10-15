import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/services/language_service.dart';
import 'package:school_management_system/core/services/translation_service.dart';

/// 📁 إدارة حالة اللغة
///
/// - تُحمّل اللغة المحفوظة عند البدء
/// - تُحمّل الترجمة المقابلة **قبل** إطلاق الحالة الجديدة
/// - تُوفّر `Locale` لـ `MaterialApp` (ويتولّى هو ضبط RTL/LTR تلقائيًا)
///
/// ملاحظة: لا نُعرّف هنا `isRTL` ولا أسماء اللغات العربية، لأن مصدر الحقيقة
/// للاتجاه هو `Directionality` (عبر `context.isRTL`)، وأسماء اللغات موجودة
/// في ملفات الترجمة (`settings.arabic` …).
class LanguageCubit extends Cubit<Locale> {
  LanguageCubit({LanguageService? languageService})
      : _languageService = languageService ?? LanguageService.instance,
        super(_defaultLocale) {
    _loadSavedLanguage();
  }

  /// اللغة الافتراضية
  static const Locale _defaultLocale = Locale('ar');

  /// اللغات المدعومة
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  final LanguageService _languageService;

  // ============================================
  // Getters
  // ============================================

  /// اللغة الحالية
  Locale get currentLocale => state;

  /// كود اللغة الحالية (`ar`, `en`, `fr`)
  String get currentLanguageCode => state.languageCode;

  // ============================================
  // التحميل
  // ============================================

  /// تحميل اللغة المحفوظة + ترجمتها
  Future<void> _loadSavedLanguage() async {
    try {
      final Locale saved = await _languageService.getLocale();
      await TranslationService.instance.loadTranslations(saved.languageCode);
      if (isClosed) return;
      emit(saved);
    } catch (error) {
      _log('🔴 خطأ في تحميل اللغة: $error');
      if (isClosed) return;
      emit(_defaultLocale);
    }
  }

  // ============================================
  // تغيير اللغة
  // ============================================

  /// تغيير اللغة
  ///
  /// - يُحمّل الترجمة الجديدة أولًا، ولا يُطلق الحالة إن فشل التحميل
  /// - يحفظ التفضيل ثم يُطلق الحالة
  Future<void> changeLocale(Locale locale) async {
    // نفس اللغة الحالية؟ لا حاجة لعمل شيء
    if (locale.languageCode == state.languageCode) {
      return;
    }

    // القيم تأتي من الواجهة، لذا نتحقق من الدعم
    if (!_isSupported(locale)) {
      _log('⚠️ اللغة "$locale" غير مدعومة');
      return;
    }

    try {
      final bool loaded =
          await TranslationService.instance.loadTranslations(locale.languageCode);

      if (!loaded) {
        _log('🔴 فشل تحميل الترجمة، أُلغي تغيير اللغة');
        return;
      }

      await _languageService.saveLocale(locale);

      if (isClosed) return;
      emit(locale);
      _log('✅ تم تغيير اللغة إلى: ${locale.languageCode}');
    } catch (error) {
      _log('🔴 خطأ في تغيير اللغة: $error');
    }
  }

  /// تغيير إلى العربية
  Future<void> changeToArabic() => changeLocale(const Locale('ar'));

  /// تغيير إلى الإنجليزية
  Future<void> changeToEnglish() => changeLocale(const Locale('en'));

  /// تغيير إلى الفرنسية
  Future<void> changeToFrench() => changeLocale(const Locale('fr'));

  // ============================================
  // دوال مساعدة
  // ============================================

  /// التحقق من دعم اللغة
  bool _isSupported(Locale locale) {
    for (final Locale supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }

  /// طباعة في وضع التطوير فقط
  void _log(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }
}
