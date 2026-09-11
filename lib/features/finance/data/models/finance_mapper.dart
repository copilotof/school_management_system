import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/finance/domain/entities/payment_entity.dart';

extension PaymentMapper on Payment {
  PaymentEntity toEntity() {
    return PaymentEntity(
      id: id,
      studentId: studentId,
      groupId: groupId,
      type: type,
      monthYear: monthYear,
      amount: amount,
      originalAmount: originalAmount,
      remainingAmount: remainingAmount,
      paymentDate: paymentDate,
      method: method,
      receiptNumber: receiptNumber,
      notes: notes,
      recordedBy: recordedBy,
    );
  }

  static PaymentsCompanion fromEntity(PaymentEntity entity) {
    return PaymentsCompanion.insert(
      studentId: entity.studentId,
      groupId: Value(entity.groupId),
      type: entity.type,
      monthYear: Value(entity.monthYear),
      amount: entity.amount,
      originalAmount: entity.originalAmount,
      remainingAmount: Value(entity.remainingAmount),
      paymentDate: Value(entity.paymentDate),
      method: Value(entity.method),
      receiptNumber: entity.receiptNumber,
      notes: Value(entity.notes),
      recordedBy: Value(entity.recordedBy),
    );
  }
}
