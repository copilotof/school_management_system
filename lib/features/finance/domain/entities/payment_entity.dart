import 'package:equatable/equatable.dart';

/// 📁 كيان العملية المالية - مبسط

class PaymentEntity extends Equatable {
  final int? id;
  final int studentId;
  final int? groupId; // الفوج
  final int? sessionId;
  final int? parentPaymentId; // ✅ مرتبط بالحصة الإضافية الأصلية
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
    this.sessionId,
    this.parentPaymentId, // ✅
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

  /// ✅ مفتاح النوع — يُترجَم في الواجهة عبر `context.tr(...)`
  ///
  /// الكيان لا يملك `BuildContext` فلا يكتب نصًا عربيًا مباشرًا
  /// (المفاتيح `finance.*` جاهزة في اللغات الثلاث).
  String get typeKey {
    switch (type) {
      case 'monthly':
        return 'finance.monthly';
      case 'advance':
        return 'finance.advance';
      case 'exemption':
        return 'finance.exemption';
      case 'reduction':
        return 'finance.reduction';
      case 'registration':
        return 'finance.registration';
      case 'extra':
        return 'finance.extra';
      case 'extra_payment':
        return 'finance.extraPayment'; // ✅
      default:
        return type;
    }
  }
  /*   /// هل مدفوعة بالكامل؟
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
 */

  bool get isFullyPaid => remainingAmount <= 0 && amount >= originalAmount;
  bool get isPartial => remainingAmount > 0;

  PaymentEntity copyWith({
    int? id,
    int? studentId,
    int? groupId,
    int? sessionId,
    String? type,
    String? monthYear,
    double? amount,
    double? originalAmount,
    double? remainingAmount,
    DateTime? paymentDate,
    String? method,
    String? receiptNumber,
    String? notes,
    int? recordedBy,
  }) {
    return PaymentEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      groupId: groupId ?? this.groupId,
      sessionId: sessionId ?? this.sessionId,
      type: type ?? this.type,
      monthYear: monthYear ?? this.monthYear,
      amount: amount ?? this.amount,
      originalAmount: originalAmount ?? this.originalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      method: method ?? this.method,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      notes: notes ?? this.notes,
      recordedBy: recordedBy ?? this.recordedBy,
    );
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    groupId,
    sessionId,
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
