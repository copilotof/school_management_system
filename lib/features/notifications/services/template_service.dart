import 'package:school_management_system/core/services/translation_service.dart';

/// 📁 خدمة معالجة قوالب الرسائل
class TemplateService {
  /// ✅ استبدال المتغيرات في القالب
  /// مثال: "الطالب {studentName}" → "الطالب أحمد"
  String render({
    required String template,
    required Map<String, String> variables,
  }) {
    var result = template;
    for (final entry in variables.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  /// ✅ توليد رسالة إلغاء حصة
  String renderSessionCancelled({
    required String groupName,
    required String date,
    required String startTime,
    required String endTime,
    required String reason,
  }) {
    return render(
      // ✅ القالب من ملفات الترجمة (ar/en/fr) بدل نص عربي مكتوب في الكود
      template: TranslationService.instance.tr('smsTemplates.sessionCancelled'),
      variables: {
        'groupName': groupName,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'reason': reason,
      },
    );
  }

  /// ✅ توليد رسالة حصة تعويضية
  String renderMakeupSession({
    required String groupName,
    required String date,
    required String startTime,
    required String endTime,
  }) {
    return render(
      template: TranslationService.instance.tr('smsTemplates.makeupSession'),
      variables: {
        'groupName': groupName,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
      },
    );
  }

  /// ✅ توليد رسالة تأجيل حصة
  String renderPostponedSession({
    required String groupName,
    required String oldDate,
    required String newDate,
  }) {
    return render(
      template: TranslationService.instance.tr(
        'smsTemplates.postponedSession',
      ),
      variables: {
        'groupName': groupName,
        'oldDate': oldDate,
        'newDate': newDate,
      },
    );
  }

  /// ✅ توليد رسالة تجاوز حد الغياب
  String renderAbsenceAlert({
    required String studentName,
    required int absentCount,
    required int threshold,
  }) {
    return render(
      template: TranslationService.instance.tr('smsTemplates.absenceAlert'),
      variables: {
        'studentName': studentName,
        'absentCount': absentCount.toString(),
        'threshold': threshold.toString(),
      },
    );
  }

  /// ✅ توليد رسالة تذكير بالدفع
  String renderPaymentReminder({
    required String studentName,
    required double debt,
    required int months,
  }) {
    return render(
      template: TranslationService.instance.tr('smsTemplates.paymentReminder'),
      variables: {
        'studentName': studentName,
        'debt': debt.toStringAsFixed(0),
        'months': months.toString(),
      },
    );
  }
}
