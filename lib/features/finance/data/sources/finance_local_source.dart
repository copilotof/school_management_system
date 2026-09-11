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

  /// ✅ إجمالي الإيرادات
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
}
