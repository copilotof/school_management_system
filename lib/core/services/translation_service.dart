import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 📁 خدمة الترجمة
class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  Map<String, dynamic> _translations = {};
  String _currentLocale = 'ar';

  String get currentLocale => _currentLocale;
  int get translationCount => getAllKeys().length;

  /// ✅ تحميل الترجمة
  Future<void> loadTranslations(String locale) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/translations/$locale.json',
      );
      _translations = jsonDecode(jsonString) as Map<String, dynamic>;
      _currentLocale = locale;
      debugPrint(
        '✅ تم تحميل الترجمة: $locale (${_countKeys(_translations)} مفتاح)',
      );
    } catch (e) {
      debugPrint('🔴 خطأ في تحميل الترجمة: $e');
      if (locale != 'ar') {
        await loadTranslations('ar');
      }
    }
  }

  /// ✅ الحصول على ترجمة مفتاح
  String tr(String key, {Map<String, String>? params}) {
    final parts = key.split('.');
    dynamic current = _translations;

    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        debugPrint('⚠️ مفتاح ترجمة غير موجود: $key');
        return key.split('.').last;
      }
    }

    String result = current.toString();

    // ✅ استبدال المتغيرات
    if (params != null && params.isNotEmpty) {
      params.forEach((k, v) {
        result = result.replaceAll('{$k}', v);
      });
    }

    return result;
  }

  /// ✅ التحقق من وجود مفتاح
  bool hasKey(String key) {
    final parts = key.split('.');
    dynamic current = _translations;

    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return false;
      }
    }
    return true;
  }

  /// ✅ جميع المفاتيح
  List<String> getAllKeys() {
    final keys = <String>[];

    void traverse(Map<String, dynamic> map, String prefix) {
      map.forEach((key, value) {
        final fullKey = prefix.isEmpty ? key : '$prefix.$key';
        if (value is Map) {
          traverse(Map<String, dynamic>.from(value), fullKey);
        } else {
          keys.add(fullKey);
        }
      });
    }

    traverse(_translations, '');
    return keys;
  }

  /// ✅ عدد المفاتيح (مساعد)
  int _countKeys(Map<String, dynamic> map) {
    int count = 0;
    for (final value in map.values) {
      if (value is Map) {
        count += _countKeys(Map<String, dynamic>.from(value));
      } else {
        count++;
      }
    }
    return count;
  }
}
