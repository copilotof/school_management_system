import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';

class FinanceLocalDataSource {
  final AppDatabase db;

  FinanceLocalDataSource({required this.db});

  // ====== العمليات المالية (Payments) ======
  Future<List<Payment>> getAllPayments() async {
    return await (db.select(db.payments)..orderBy([
          (t) =>
              OrderingTerm(expression: t.paymentDate, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<List<Payment>> getPaymentsByStudent(int studentId) async {
    return await (db.select(db.payments)
          ..where((t) => t.studentId.equals(studentId))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.paymentDate,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<List<Payment>> getPaymentsByStudentAndGroup(
    int studentId,
    int groupId,
  ) async {
    return await (db.select(db.payments)
          ..where(
            (t) => t.studentId.equals(studentId) & t.groupId.equals(groupId),
          )
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.paymentDate,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  /// ✅ المتأخرات - العمليات التي لها متبقي
  Future<List<Payment>> getOutstandingPayments() async {
    return await (db.select(
      db.payments,
    )..where((t) => t.remainingAmount.isBiggerThanValue(0))).get();
  }

  Future<int> createPayment(PaymentsCompanion payment) async {
    return await db.into(db.payments).insert(payment);
  }

  Future<bool> updatePayment(Payment payment) async {
    return await db.update(db.payments).replace(payment);
  }

  Future<int> deletePayment(int id) async {
    return await (db.delete(db.payments)..where((t) => t.id.equals(id))).go();
  }

  /// ✅ الأشهر المدفوعة لطالب في فوج معين
  Future<Set<String>> getPaidMonths(int studentId, int groupId) async {
    final payments = await getPaymentsByStudentAndGroup(studentId, groupId);
    final months = <String>{};
    for (final payment in payments) {
      if (payment.monthYear != null) {
        months.add(payment.monthYear!);
      }
      // ✅ الدفع المسبق يغطي عدة أشهر
      if (payment.type == 'advance' &&
          payment.monthYear != null &&
          payment.notes != null) {
        // notes تحتوي على نطاق الأشهر مثل "2026-07 إلى 2026-09"
        final match = RegExp(r'(\d{4}-\d{2})').allMatches(payment.notes!);
        for (final m in match) {
          months.add(m.group(0)!);
        }
      }
    }
    return months;
  }

  /// ✅ إجمالي المدفوع لطالب
  Future<double> getTotalPaidByStudent(int studentId) async {
    final payments = await getPaymentsByStudent(studentId);
    return payments
        .where((p) => p.type != 'exemption')
        .fold<double>(0, (sum, p) => sum + p.amount);
  }

  /// ✅ إجمالي المتبقي لطالب
  Future<double> getTotalRemainingByStudent(int studentId) async {
    final payments = await getPaymentsByStudent(studentId);
    return payments.fold<double>(0, (sum, p) => sum + p.remainingAmount);
  }

  /*   /// ✅ إجمالي الإيرادات
  Future<double> getTotalRevenue() async {
    final payments = await getAllPayments();
    return payments
        .where((p) => p.type != 'exemption')
        .fold<double>(0, (sum, p) => sum + p.amount);
  }

  /// ✅ إجمالي المتأخرات
  Future<double> getTotalOutstanding() async {
    final payments = await getAllPayments();
    return payments.fold<double>(0, (sum, p) => sum + p.remainingAmount);
  }
 */
  /// ✅ إجمالي الإيرادات = مجموع الدفعات المقبوضة فعلياً
  Future<double> getTotalRevenue() async {
    final payments = await getAllPayments();

    // ✅ نحسب فقط الدفعات التي تم استلامها فعلياً
    // نستثني:
    // - type == 'exemption' (إعفاء، لا يوجد دفع)
    // - type == 'extra' (الحصة الأصلية، الدفعات الفعلية في extra_payment)
    return payments
        .where((p) => p.type != 'exemption' && p.type != 'extra')
        .fold<double>(0, (sum, p) => sum + p.amount);
  }

  /// ✅ إجمالي المتأخرات = الأشهر غير المدفوعة + المتبقي من الدفعات الجزئية + الحصص الإضافية
  Future<double> getTotalOutstanding() async {
    double total = 0;

    // ============================================
    // 1. الأشهر غير المدفوعة (من التسجيل حتى الشهر الماضي)
    // ============================================
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    // جلب كل التسجيلات النشطة
    final enrollments = await (db.select(
      db.enrollments,
    )..where((t) => t.status.equals('active'))).get();

    // جلب كل الأفواج
    final groups = await db.select(db.groups).get();

    // جلب كل الدفعات
    final payments = await getAllPayments();

    for (final enrollment in enrollments) {
      final group = groups.where((g) => g.id == enrollment.groupId).firstOrNull;
      if (group == null) continue;

      // الأشهر المدفوعة لهذا الطالب في هذا الفوج
      final paidMonths = <String>{};
      for (final p in payments.where(
        (p) =>
            p.studentId == enrollment.studentId &&
            p.groupId == enrollment.groupId,
      )) {
        if (p.monthYear != null) {
          paidMonths.add(p.monthYear!);
        }
        // الدفع المسبق يغطي عدة أشهر
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
              paidMonths.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
            }
          }
        }
      }

      // الأشهر غير المدفوعة من التسجيل حتى الشهر الماضي
      final enrollmentDate = enrollment.enrollmentDate;
      final startMonth = DateTime(enrollmentDate.year, enrollmentDate.month, 1);

      for (
        DateTime date = startMonth;
        !date.isAfter(lastMonth);
        date = DateTime(date.year, date.month + 1, 1)
      ) {
        final monthYear =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';
        if (!paidMonths.contains(monthYear)) {
          total += group.monthlyFee;
        }
      }
    }

    // ============================================
    // 2. المتبقي من الدفعات الجزئية + الحصص الإضافية
    // ============================================
    total += payments
        .where(
          (p) =>
              p.remainingAmount > 0 &&
              p.type != 'extra_payment' &&
              p.type != 'exemption',
        )
        .fold<double>(0, (sum, p) => sum + p.remainingAmount);

    return total;
  }
}
