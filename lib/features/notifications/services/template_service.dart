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
      template:
          'السيد(ة) ولي أمر الطالب،\n'
          'نود إعلامكم بأنه تم إلغاء الحصة الخاصة بفوج {groupName}.\n'
          'التاريخ: {date}\n'
          'الوقت: {startTime} - {endTime}\n'
          'السبب: {reason}\n'
          'شكراً لتفهمكم.',
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
      template:
          'السيد(ة) ولي أمر الطالب،\n'
          'تم جدولة حصة تعويضية لفوج {groupName}.\n'
          'التاريخ: {date}\n'
          'الوقت: {startTime} - {endTime}\n'
          'شكراً لكم.',
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
      template:
          'السيد(ة) ولي أمر الطالب،\n'
          'تم تأجيل الحصة الخاصة بفوج {groupName}.\n'
          'من: {oldDate}\n'
          'إلى: {newDate}\n'
          'شكراً لكم.',
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
      template:
          'السيد(ة) ولي أمر الطالب {studentName}،\n'
          'نود إعلامكم بأن الطالب تجاوز الحد المسموح من الغيابات.\n'
          'عدد الغيابات: {absentCount} / {threshold}\n'
          'نرجو المتابعة.',
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
      template:
          'السيد(ة) ولي أمر الطالب {studentName}،\n'
          'نود تذكيركم بوجود متأخرات بمبلغ {debt} دج.\n'
          'عدد الأشهر المتأخرة: {months}\n'
          'نرجو التسديد في أقرب وقت.\n'
          'شكراً لكم.',
      variables: {
        'studentName': studentName,
        'debt': debt.toStringAsFixed(0),
        'months': months.toString(),
      },
    );
  }
}
