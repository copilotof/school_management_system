import 'package:flutter/material.dart';
import 'package:school_management_system/core/services/translation_service.dart';

/// 📁 Extension للترجمة على BuildContext
extension TranslationExtension on BuildContext {
  /// ترجمة مفتاح
  /// مثال: context.tr('students.title')
  /// مع متغيرات: context.tr('messages.countItems', params: {'count': '5'})
  String tr(String key, {Map<String, String>? params}) {
    return TranslationService.instance.tr(key, params: params);
  }

  /// التحقق من وجود مفتاح
  bool hasTranslation(String key) {
    return TranslationService.instance.hasKey(key);
  }
}
