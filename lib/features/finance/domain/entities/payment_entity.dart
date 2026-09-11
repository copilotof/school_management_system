import 'package:equatable/equatable.dart';

/// 📁 كيان العملية المالية - مبسط

class PaymentEntity extends Equatable {
  final int? id;
  final int studentId;
  final int? groupId; // الفوج
  final String
  type; // monthly, advance, exemption, reduction, registration, extra
  final String? monthYear; // "2026-07"
  final double amount; // المبلغ المدفوع
  final double originalAmount; // المبلغ الإجمالي
  final double remainingAmount; // المتبقي
  final DateTime paymentDate;
  final String method;
  final String receiptNumber;
  final String? notes;
  final int? recordedBy;

  const PaymentEntity({
    this.id,
    required this.studentId,
    this.groupId,
    required this.type,
    this.monthYear,
    required this.amount,
    required this.originalAmount,
    this.remainingAmount = 0,
    required this.paymentDate,
    this.method = 'cash',
    required this.receiptNumber,
    this.notes,
    this.recordedBy,
  });

  /// تسمية النوع
  String get typeLabel {
    switch (type) {
      case 'monthly':
        return 'شهرية';
      case 'advance':
        return 'دفع مسبق';
      case 'exemption':
        return 'إعفاء';
      case 'reduction':
        return 'تخفيض';
      case 'registration':
        return 'تسجيل';
      case 'extra':
        return 'إضافية';
      default:
        return type;
    }
  }

  /// هل مدفوعة بالكامل؟
  bool get isFullyPaid => remainingAmount <= 0 && amount >= originalAmount;

  /// هل جزئية؟
  bool get isPartial => remainingAmount > 0;

  @override
  List<Object?> get props => [
    id,
    studentId,
    groupId,
    type,
    monthYear,
    amount,
    originalAmount,
    remainingAmount,
    paymentDate,
    method,
    receiptNumber,
    notes,
    recordedBy,
  ];
}
