import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 📁 خدمة الترجمة
///
/// - تحمّل ملفات JSON من `assets/translations/`
/// - تُخزّن النصوص في ذاكرة مؤقتة (Cache) لتفادي تكرار التحليل والبحث
/// - تدعم المفاتيح المتداخلة: `students.personalInfo.firstName`
/// - تدعم المتغيرات: `tr('key', params: {'name': 'أحمد'})`
/// - تجمع المفاتيح الناقصة في `missingKeys` لاكتمال ملفات الترجمة
class TranslationService {
  TranslationService._();

  static final TranslationService instance = TranslationService._();

  /// مجلد ملفات الترجمة
  static const String _basePath = 'assets/translations';

  /// اللغة الافتراضية
  static const String _defaultLocale = 'ar';

  /// اللغات المدعومة
  static const List<String> supportedLocales = <String>['ar', 'en', 'fr'];

  /// خريطة الترجمة الحالية
  Map<String, dynamic> _translations = const <String, dynamic>{};

  /// اللغة الحالية
  String _currentLocale = _defaultLocale;

  /// قائمة مسطّحة بكل المفاتيح (تُبنى مرة واحدة عند التحميل)
  List<String> _flatKeys = const <String>[];

  /// هل الترجمة محمّلة؟
  bool _isLoaded = false;

  /// 🚀 ذاكرة النصوص الجاهزة (مفتاح ← نص بدون متغيرات)
  ///
  /// هذا هو العلاج الأساسي للبطء: بدل تنفيذ `split('.')` والمرور على
  /// الخريطة وتحويل القيمة إلى نص في كل نداء `context.tr(...)`
  /// (وهي مئات النداءات في كل إطار)، تصبح التكلفة بحثًا واحدًا.
  final Map<String, String> _cache = <String, String>{};

  /// المفاتيح المطلوبة وغير الموجودة في ملف الترجمة
  final Set<String> _missingKeys = <String>{};

  // ============================================
  // Getters
  // ============================================

  /// اللغة الحالية
  String get currentLocale => _currentLocale;

  /// عدد النصوص المحمّلة
  int get translationCount => _flatKeys.length;

  /// هل الترجمة محمّلة؟
  bool get isLoaded => _isLoaded;

  /// المفاتيح الناقصة (للقراءة فقط) — استخدمها لمعرفة ما يجب إضافته للـ JSON
  Set<String> get missingKeys => Set<String>.unmodifiable(_missingKeys);

  // ============================================
  // التحميل
  // ============================================

  /// ✅ تحميل ترجمة لغة معيّنة
  ///
  /// تُعيد `true` عند النجاح، و`false` عند الفشل التام.
  Future<bool> loadTranslations(String locale) async {
    // التحقق من الدعم
    if (!supportedLocales.contains(locale)) {
      _log('⚠️ اللغة "$locale" غير مدعومة، استخدام "$_defaultLocale"');
      locale = _defaultLocale;
    }

    // محمّلة مسبقًا؟ لا حاجة لإعادة القراءة من القرص
    if (_isLoaded && _currentLocale == locale) {
      return true;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        '$_basePath/$locale.json',
      );

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('ملف الترجمة ليس JSON صحيحًا');
      }

      _translations = decoded;
      _currentLocale = locale;
      _flatKeys = _extractFlatKeys(decoded);
      _cache.clear(); // لا بد من إفراغ الذاكرة عند تبديل اللغة
      _isLoaded = true;

      _log('✅ تم تحميل الترجمة: $locale (${_flatKeys.length} مفتاح)');
      return true;
    } catch (error) {
      _log('🔴 خطأ في تحميل الترجمة "$locale": $error');

      // محاولة العودة إلى اللغة الافتراضية
      if (locale != _defaultLocale) {
        return loadTranslations(_defaultLocale);
      }

      // فشل تام
      _translations = const <String, dynamic>{};
      _flatKeys = const <String>[];
      _cache.clear();
      _isLoaded = false;
      return false;
    }
  }

  // ============================================
  // الوصول للترجمة
  // ============================================

  /// ✅ ترجمة مفتاح
  ///
  /// - يدعم المفاتيح المتداخلة: `students.personalInfo.firstName`
  /// - يدعم المتغيرات: `tr('hello', params: {'name': 'أحمد'})`
  /// - يُعيد آخر جزء من المفتاح إذا لم يوجد (حتى لا يظهر فراغ في الواجهة)
  String tr(String key, {Map<String, String>? params}) {
    final bool hasParams = params != null && params.isNotEmpty;

    // 🚀 المسار السريع: نص بدون متغيرات ومحفوظ في الذاكرة
    if (!hasParams) {
      final String? cached = _cache[key];
      if (cached != null) {
        return cached;
      }
    }

    if (!_isLoaded) {
      return _lastPart(key);
    }

    final dynamic value = _findValue(key);
    if (value == null) {
      // نسجّل المفتاح الناقص مرة واحدة فقط (بدل إغراق السجل)
      if (_missingKeys.add(key)) {
        _log('⚠️ مفتاح ترجمة غير موجود: $key');
      }
      return _lastPart(key);
    }

    String result = value.toString();

    if (hasParams) {
      result = _replaceParams(result, params);
    } else {
      _cache[key] = result;
    }

    return result;
  }

  /// ✅ التحقق من وجود مفتاح
  bool hasKey(String key) => _findValue(key) != null;

  /// ✅ جميع المفاتيح (قائمة غير قابلة للتعديل من الخارج)
  List<String> getAllKeys() => List<String>.unmodifiable(_flatKeys);

  // ============================================
  // إعادة التعيين
  // ============================================

  /// ✅ إعادة تعيين الخدمة وتحرير الذاكرة
  void reset() {
    _translations = const <String, dynamic>{};
    _flatKeys = const <String>[];
    _cache.clear();
    _missingKeys.clear();
    _currentLocale = _defaultLocale;
    _isLoaded = false;
    _log('🔄 تم إعادة تعيين خدمة الترجمة');
  }

  // ============================================
  // دوال مساعدة داخلية
  // ============================================

  /// البحث عن قيمة مفتاح في الخريطة
  dynamic _findValue(String key) {
    final List<String> parts = key.split('.');
    dynamic current = _translations;

    for (final String part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current;
  }

  /// استبدال المتغيرات في النص: {name} ← أحمد
  String _replaceParams(String template, Map<String, String> params) {
    String result = template;
    for (final MapEntry<String, String> entry in params.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  /// آخر جزء من المفتاح — احتياطي عند غياب الترجمة
  String _lastPart(String key) {
    final List<String> parts = key.split('.');
    return parts.isNotEmpty ? parts.last : key;
  }

  /// استخراج كل المفاتيح كقائمة مسطّحة (مرة واحدة عند التحميل)
  List<String> _extractFlatKeys(
    Map<String, dynamic> map, [
    String prefix = '',
  ]) {
    final List<String> keys = <String>[];

    for (final MapEntry<String, dynamic> entry in map.entries) {
      final String fullKey =
          prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      final dynamic value = entry.value;

      if (value is Map) {
        keys.addAll(
          _extractFlatKeys(Map<String, dynamic>.from(value), fullKey),
        );
      } else {
        keys.add(fullKey);
      }
    }

    return keys;
  }

  /// طباعة في وضع التطوير فقط
  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
