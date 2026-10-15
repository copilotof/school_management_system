import 'package:equatable/equatable.dart';

/// 📁 كيان المستحق المالي
/// يمثل أي مبلغ مستحق على الطالب

class InvoiceEntity extends Equatable {
  final int? id;
  final String invoiceNumber; // رقم الفاتورة
  final int studentId; // الطالب
  final int? groupId; // الفوج المرتبط (اختياري)
  final String? studentName; // اسم الطالب (للعرض)
  final String type; // registration, monthly, extra_session, custom
  final String description; // الوصف
  final double amount; // المبلغ الأصلي
  final DateTime dueDate; // تاريخ الاستحقاق
  final String status; // unpaid, partially_paid, paid, exempted, cancelled
  final double paidAmount; // المبلغ المدفوع (محسوب)
  final double remainingAmount; // المتبقي (محسوب)
  final DateTime? createdAt;

  const InvoiceEntity({
    this.id,
    required this.invoiceNumber,
    required this.studentId,
    this.groupId,
    this.studentName,
    required this.type,
    required this.description,
    required this.amount,
    required this.dueDate,
    this.status = 'unpaid',
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.createdAt,
  });

  /// المبلغ المتبقي
  double get remaining => amount - paidAmount;

  /// هل مدفوعة بالكامل؟
  bool get isPaid => remaining <= 0;

  /// ✅ مفتاح نوع المستحق — يُترجَم في الواجهة عبر `context.tr(...)`
  ///
  /// ملاحظة: مُعاد استخدام مفاتيح `finance.*` القائمة (تسجيل/شهرية/حصة إضافية)
  /// بدل إنشاء مفاتيح مكرّرة — والفرق الوحيد `finance.customType` (مخصص).
  String get typeKey {
    switch (type) {
      case 'registration':
        return 'finance.registration';
      case 'monthly':
        return 'finance.monthly';
      case 'extra_session':
        return 'finance.extra';
      case 'custom':
        return 'finance.customType';
      default:
        return type;
    }
  }

  /// ✅ مفتاح الحالة — يُترجَم في الواجهة عبر `context.tr(...)`
  String get statusKey {
    switch (status) {
      case 'unpaid':
        return 'finance.notPaid';
      case 'partially_paid':
        return 'finance.partialPaid';
      case 'paid':
        return 'finance.paid';
      case 'exempted':
        return 'finance.exempted';
      case 'cancelled':
        return 'attendance.cancelled';
      default:
        return status;
    }
  }

  InvoiceEntity copyWith({
    int? id,
    String? invoiceNumber,
    int? studentId,
    int? groupId,
    String? studentName,
    String? type,
    String? description,
    double? amount,
    DateTime? dueDate,
    String? status,
    double? paidAmount,
    double? remainingAmount,
    DateTime? createdAt,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      studentId: studentId ?? this.studentId,
      groupId: groupId ?? this.groupId,
      studentName: studentName ?? this.studentName,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    invoiceNumber,
    studentId,
    groupId,
    studentName,
    type,
    description,
    amount,
    dueDate,
    status,
    paidAmount,
    remainingAmount,
    createdAt,
  ];
}
