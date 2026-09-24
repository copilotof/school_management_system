import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:school_management_system/core/database/app_database.dart';

/// 📁 خدمة الإشعارات التلقائية
class AutoNotificationService {
  final AppDatabase db;

  AutoNotificationService({required this.db});

  /// ✅ 1. فحص الغيابات وإنشاء إشعارات
  Future<int> checkAttendanceLimit({
    required int studentId,
    required int threshold,
  }) async {
    try {
      // عدد الغيابات (absent فقط)
      final absences =
          await (db.select(db.attendance)..where(
                (t) =>
                    t.studentId.equals(studentId) & t.status.equals('absent'),
              ))
              .get();

      final absentCount = absences.length;

      debugPrint('🟡 فحص غيابات الطالب $studentId: $absentCount / $threshold');

      if (absentCount < threshold) {
        return 0; // لم يتجاوز الحد
      }

      // ✅ التحقق من عدم وجود إشعار سابق
      final existing =
          await (db.select(db.notifications)..where(
                (t) =>
                    t.type.equals('attendance') &
                    t.recipientId.equals(studentId) &
                    t.isRead.equals(false),
              ))
              .getSingleOrNull();

      if (existing != null) {
        debugPrint('   - يوجد إشعار غياب سابق للطالب');
        return 0;
      }

      // جلب اسم الطالب
      final student = await (db.select(
        db.students,
      )..where((t) => t.id.equals(studentId))).getSingleOrNull();

      if (student == null) return 0;

      final studentName = '${student.firstName} ${student.lastName}'.trim();

      // ✅ إنشاء الإشعار
      await db
          .into(db.notifications)
          .insert(
            NotificationsCompanion.insert(
              title: 'تنبيه غياب - $studentName',
              body:
                  'تجاوز الطالب $studentName الحد المسموح من الغيابات ($absentCount / $threshold).',
              type: 'attendance',
              recipientType: 'student',
              recipientId: Value(studentId),
              channel: const Value('in_app'),
              metadata: Value(
                '{"absentCount": $absentCount, "threshold": $threshold}',
              ),
            ),
          );

      debugPrint('   ✅ تم إنشاء إشعار غياب للطالب $studentId');
      return 1;
    } catch (e) {
      debugPrint('🔴 خطأ في فحص الغيابات: $e');
      return 0;
    }
  }

  /// ✅ 2. فحص المتأخرات وإنشاء إشعارات
  Future<int> checkPaymentOverdue() async {
    try {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      // جلب كل التسجيلات النشطة
      final enrollments = await (db.select(
        db.enrollments,
      )..where((t) => t.status.equals('active'))).get();

      // جلب الأفواج
      final groups = await db.select(db.groups).get();

      // جلب الدفعات
      final payments = await db.select(db.payments).get();

      int created = 0;

      for (final enrollment in enrollments) {
        final group = groups
            .where((g) => g.id == enrollment.groupId)
            .firstOrNull;
        if (group == null) continue;

        // الأشهر المدفوعة
        final paidMonths = <String>{};
        for (final p in payments.where(
          (p) =>
              p.studentId == enrollment.studentId &&
              p.groupId == enrollment.groupId,
        )) {
          if (p.monthYear != null) paidMonths.add(p.monthYear!);
          if (p.type == 'advance' && p.notes != null) {
            final match = RegExp(r'(\d{4}-\d{2})').allMatches(p.notes!);
            final monthList = match.map((m) => m.group(0)!).toList();
            if (monthList.length >= 2) {
              final start = DateTime.parse('${monthList[0]}-01');
              final end = DateTime.parse('${monthList[1]}-01');
              for (
                DateTime d = start;
                !d.isAfter(end);
                d = DateTime(d.year, d.month + 1, 1)
              ) {
                paidMonths.add(
                  '${d.year}-${d.month.toString().padLeft(2, '0')}',
                );
              }
            }
          }
        }

        // عدد الأشهر المتأخرة
        int unpaidMonthsCount = 0;
        final enrollmentDate = enrollment.enrollmentDate;
        final startMonth = DateTime(
          enrollmentDate.year,
          enrollmentDate.month,
          1,
        );

        for (
          DateTime date = startMonth;
          !date.isAfter(lastMonth);
          date = DateTime(date.year, date.month + 1, 1)
        ) {
          final monthYear =
              '${date.year}-${date.month.toString().padLeft(2, '0')}';
          if (!paidMonths.contains(monthYear)) {
            unpaidMonthsCount++;
          }
        }

        if (unpaidMonthsCount == 0) continue;

        // المتبقي من الدفعات الجزئية
        final partialRemaining = payments
            .where(
              (p) =>
                  p.studentId == enrollment.studentId &&
                  p.groupId == enrollment.groupId &&
                  p.remainingAmount > 0 &&
                  p.type != 'extra_payment' &&
                  p.type != 'exemption',
            )
            .fold<double>(0, (sum, p) => sum + p.remainingAmount);

        final totalDebt =
            (unpaidMonthsCount * group.monthlyFee) + partialRemaining;

        // التحقق من عدم وجود إشعار سابق
        final existing =
            await (db.select(db.notifications)..where(
                  (t) =>
                      t.type.equals('payment') &
                      t.recipientId.equals(enrollment.studentId) &
                      t.isRead.equals(false),
                ))
                .getSingleOrNull();

        if (existing != null) continue;

        // جلب اسم الطالب
        final student = await (db.select(
          db.students,
        )..where((t) => t.id.equals(enrollment.studentId))).getSingleOrNull();

        if (student == null) continue;

        final studentName = '${student.firstName} ${student.lastName}'.trim();

        // ✅ إنشاء الإشعار
        await db
            .into(db.notifications)
            .insert(
              NotificationsCompanion.insert(
                title: 'تذكير بالدفع - $studentName',
                body:
                    'يوجد متأخرات على الطالب $studentName بمبلغ ${totalDebt.toStringAsFixed(0)} دج ($unpaidMonthsCount أشهر + دفعات جزئية).',
                type: 'payment',
                recipientType: 'guardian',
                recipientId: Value(enrollment.studentId),
                channel: const Value('in_app'),
                metadata: Value(
                  '{"debt": $totalDebt, "months": $unpaidMonthsCount}',
                ),
              ),
            );

        created++;
      }

      debugPrint('🟢 تم إنشاء $created إشعار دفع');
      return created;
    } catch (e) {
      debugPrint('🔴 خطأ في فحص المتأخرات: $e');
      return 0;
    }
  }

  /// ✅ 3. إنشاء إشعار عند إلغاء حصة
  Future<int> notifySessionCancelled({
    required int sessionId,
    required int groupId,
    required String reason,
  }) async {
    try {
      // جلب اسم الفوج
      final group = await (db.select(
        db.groups,
      )..where((t) => t.id.equals(groupId))).getSingleOrNull();

      if (group == null) return 0;

      // جلب كل الطلاب في الفوج
      final enrollments =
          await (db.select(db.enrollments)..where(
                (t) => t.groupId.equals(groupId) & t.status.equals('active'),
              ))
              .get();

      int created = 0;

      for (final enrollment in enrollments) {
        await db
            .into(db.notifications)
            .insert(
              NotificationsCompanion.insert(
                title: 'إلغاء حصة - ${group.name}',
                body:
                    'تم إلغاء الحصة الخاصة بفوج ${group.name}. السبب: $reason',
                type: 'session',
                recipientType: 'student',
                recipientId: Value(enrollment.studentId),
                channel: const Value('in_app'),
                metadata: Value(
                  '{"sessionId": $sessionId, "groupId": $groupId}',
                ),
              ),
            );
        created++;
      }

      debugPrint('🟢 تم إنشاء $created إشعار إلغاء حصة');
      return created;
    } catch (e) {
      debugPrint('🔴 خطأ: $e');
      return 0;
    }
  }

  /// ✅ حذف الإشعارات القديمة (أكثر من 30 يوم)
  Future<int> cleanupOldNotifications({int daysOld = 30}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: daysOld));
      return await (db.delete(db.notifications)..where(
            (t) =>
                t.createdAt.isSmallerThanValue(cutoff) & t.isRead.equals(true),
          ))
          .go();
    } catch (e) {
      debugPrint('🔴 خطأ في الحذف: $e');
      return 0;
    }
  }
}
