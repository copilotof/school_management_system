import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/translation_service.dart';
import '../../../injection_container.dart';

/// 📁 خدمة إرسال SMS عبر فتح تطبيق الرسائل
/// ⚠️ الإرسال يدوي فقط — يفتح التطبيق برسالة جاهزة
class SmsService {
  /// ✅ فتح تطبيق الرسائل برسالة جاهزة
  /// ⚠️ يُستدعى فقط عند ضغط المستخدم على "إرسال"
  Future<SmsResult> sendSms({
    required String phone,
    required String body,
    int? recipientId,
    String? recipientName,
    String? eventCode,
  }) async {
    try {
      final formattedPhone = _formatPhone(phone);

      if (formattedPhone.isEmpty) {
        await _logSms(
          phone: phone,
          body: body,
          status: 'failed',
          errorMessage: TranslationService.instance.tr('sms.invalidNumber'),
          recipientId: recipientId,
          recipientName: recipientName,
          eventCode: eventCode,
        );
        return SmsResult(
          success: false,
          phone: phone,
          error: TranslationService.instance.tr('sms.invalidNumber'),
        );
      }

      final uri = Uri(
        scheme: 'sms',
        path: formattedPhone,
        queryParameters: {'body': body},
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);

        // ✅ تسجيل في السجل
        await _logSms(
          phone: formattedPhone,
          body: body,
          status: 'sent',
          recipientId: recipientId,
          recipientName: recipientName,
          eventCode: eventCode,
        );

        return SmsResult(success: true, phone: formattedPhone);
      } else {
        await _logSms(
          phone: phone,
          body: body,
          status: 'failed',
          errorMessage: TranslationService.instance.tr('sms.cannotOpenApp'),
          recipientId: recipientId,
          recipientName: recipientName,
          eventCode: eventCode,
        );
        return SmsResult(
          success: false,
          phone: phone,
          error: TranslationService.instance.tr('sms.cannotOpenApp'),
        );
      }
    } catch (e) {
      debugPrint('🔴 SMS error: $e');
      return SmsResult(success: false, phone: phone, error: e.toString());
    }
  }

  /// ✅ تسجيل SMS في قاعدة البيانات
  Future<void> _logSms({
    required String phone,
    required String body,
    required String status,
    String? errorMessage,
    int? recipientId,
    String? recipientName,
    String? eventCode,
  }) async {
    try {
      final db = getIt<AppDatabase>();
      await db
          .into(db.smsLogs)
          .insert(
            SmsLogsCompanion.insert(
              phone: phone,
              body: body,
              status: status,
              errorMessage: Value(errorMessage),
              recipientId: Value(recipientId),
              recipientName: Value(recipientName),
              eventCode: Value(eventCode),
            ),
          );
    } catch (e) {
      debugPrint('🔴 خطأ في تسجيل SMS: $e');
    }
  }

  /// ✅ إرسال SMS لعدة أرقام (مع Stream للتقدم)
  /// ⚠️ يفتح تطبيق الرسائل لكل رقم بالترتيب
  Stream<SmsProgress> sendBulkSms({
    required List<SmsRecipient> recipients,
    required String body,
  }) async* {
    int sent = 0;
    int failed = 0;

    for (final recipient in recipients) {
      final result = await sendSms(phone: recipient.phone, body: body);

      if (result.success) {
        sent++;
      } else {
        failed++;
      }

      yield SmsProgress(
        total: recipients.length,
        sent: sent,
        failed: failed,
        current: recipient,
        isDone: false,
      );

      // ✅ انتظار حتى يعود المستخدم من تطبيق الرسائل
      await Future.delayed(const Duration(seconds: 2));
    }

    yield SmsProgress(
      total: recipients.length,
      sent: sent,
      failed: failed,
      current: null,
      isDone: true,
    );
  }

  /// ✅ تنسيق الرقم
  String _formatPhone(String phone) {
    // إزالة كل شيء ما عدا الأرقام و +
    var formatted = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (formatted.isEmpty) return '';

    // إذا بدأ بـ 0، استبدله بـ +213
    if (formatted.startsWith('0')) {
      formatted = '+213${formatted.substring(1)}';
    }

    if (!formatted.startsWith('+')) {
      formatted = '+213$formatted';
    }

    return formatted;
  }
}

/// 📁 نتيجة إرسال SMS
class SmsResult {
  final bool success;
  final String phone;
  final String? error;

  const SmsResult({required this.success, required this.phone, this.error});
}

/// 📁 مستلم SMS
class SmsRecipient {
  final int? id;
  final String name;
  final String phone;

  const SmsRecipient({this.id, required this.name, required this.phone});
}

/// 📁 تقدم إرسال SMS
class SmsProgress {
  final int total;
  final int sent;
  final int failed;
  final SmsRecipient? current;
  final bool isDone;
  final String? error;

  const SmsProgress({
    required this.total,
    required this.sent,
    required this.failed,
    this.current,
    required this.isDone,
    this.error,
  });

  int get processed => sent + failed;
  double get percentage => total > 0 ? processed / total : 0;
}
