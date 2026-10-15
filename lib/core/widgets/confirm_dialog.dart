import 'package:flutter/material.dart';
import 'package:school_management_system/core/utils/translation_extension.dart';

/// 📁 حوار تأكيد موحّد (يُستخدم في كل الشاشات)
///
/// النصوص الافتراضية تُترجم تلقائيًا إن لم تُمرَّر، فلا توجد نصوص عربية
/// مكتوبة في الكود.
class ConfirmDialog {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ColorScheme colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelText ?? dialogContext.tr('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              child: Text(confirmText ?? dialogContext.tr('common.delete')),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
