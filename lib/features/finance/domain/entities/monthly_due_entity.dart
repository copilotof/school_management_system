import 'package:equatable/equatable.dart';

/// 📁 كيان الاستحقاق الشهري

class MonthlyDueEntity extends Equatable {
  final int? id;
  final int studentId;
  final String monthYear; // "2025-09"
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;

  const MonthlyDueEntity({
    this.id,
    required this.studentId,
    required this.monthYear,
    required this.totalAmount,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.status = 'unpaid',
  });

  bool get isPaid => status == 'paid';
  bool get isPartial => status == 'partial';
  bool get isExempted => status == 'exempted';

  @override
  List<Object?> get props => [
    id,
    studentId,
    monthYear,
    totalAmount,
    paidAmount,
    remainingAmount,
    status,
  ];
}
