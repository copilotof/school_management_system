import 'package:flutter/material.dart';
// ⚠️ `intl` تُصدّر `TextDirection` خاصة بها (LTR/RTL) تتعارض مع
// `TextDirection` من `dart:ui` (ltr/rtl) — نخفيها لنستخدم اتجاه Flutter.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:school_management_system/core/services/translation_service.dart';

/// 🚀 ذاكرة أنماط التاريخ (لغة|نمط ← DateFormat جاهز)
///
/// إنشاء `DateFormat` مكلف (تحليل النمط وبيانات اللغة)، والملف يُستخدم
/// في عشرات المواضع داخل `build` — لذا نُنشئ كائنًا واحدًا لكل تركيبة.
final Map<String, DateFormat> _dateFormats = <String, DateFormat>{};

DateFormat _dateFormatFor(String pattern, String locale) {
  final String key = '$locale|$pattern';
  return _dateFormats.putIfAbsent(key, () {
    try {
      return DateFormat(pattern, locale);
    } catch (_) {
      // بيانات اللغة غير مُهيّأة بعد (initializeDateFormatting)
      return DateFormat(pattern);
    }
  });
}

/// 📁 Extension للترجمة على BuildContext
extension TranslationExtension on BuildContext {
  // ============================================
  // الترجمة
  // ============================================

  /// ترجمة مفتاح
  /// مثال: `context.tr('students.title')`
  /// مع متغيرات: `context.tr('common.countItems', params: {'count': '5'})`
  String tr(String key, {Map<String, String>? params}) {
    return TranslationService.instance.tr(key, params: params);
  }

  /// التحقق من وجود مفتاح
  bool hasTranslation(String key) {
    return TranslationService.instance.hasKey(key);
  }

  /// ترجمة مع قيمة احتياطية إن لم يوجد المفتاح
  String trOr(
    String key, {
    required String fallback,
    Map<String, String>? params,
  }) {
    return hasTranslation(key) ? tr(key, params: params) : fallback;
  }

  // ============================================
  // معلومات اللغة والاتجاه
  // ============================================

  /// كود اللغة الحالية للواجهة (`ar`, `en`, `fr`)
  String get currentLanguageCode {
    return Localizations.maybeLocaleOf(this)?.languageCode ??
        TranslationService.instance.currentLocale;
  }

  /// هل الترجمة جاهزة؟
  bool get isTranslationLoaded => TranslationService.instance.isLoaded;

  /// ✅ الاتجاه الفعلي للواجهة
  ///
  /// نقرأه من `Directionality` (الذي يضبطه `MaterialApp` من اللغة) لا من
  /// اسم اللغة مباشرة — فيبقى صحيحًا لأي لغة RTL مستقبلًا وبلا ازدواج منطق.
  TextDirection get textDirection =>
      Directionality.maybeOf(this) ?? TextDirection.ltr;

  /// هل الواجهة من اليمين إلى اليسار؟
  bool get isRTL => textDirection == TextDirection.rtl;

  /// هل الواجهة من اليسار إلى اليمين؟
  bool get isLTR => !isRTL;

  // ============================================
  // تنسيق التاريخ والوقت (مُوطَّن وآمن)
  // ============================================

  /// تنسيق تاريخ بلغة الواجهة، مع احتياطي لا يُسقط الشاشة
  ///
  /// مثال: `context.formatDate(student.dateOfBirth!)`
  String formatDate(DateTime date, {String pattern = 'yyyy/MM/dd'}) {
    return _dateFormatFor(pattern, currentLanguageCode).format(date);
  }

  /// تنسيق الوقت (ساعة:دقيقة)
  String formatTime(DateTime date) => formatDate(date, pattern: 'HH:mm');

  /// تنسيق تاريخ ووقت
  String formatDateTime(DateTime date) =>
      formatDate(date, pattern: 'yyyy/MM/dd HH:mm');

  /// تنسيق وقت بثوانٍ (للسجلات)
  String formatTimeWithSeconds(DateTime date) =>
      formatDate(date, pattern: 'HH:mm:ss');
}
