import 'package:equatable/equatable.dart';

class ExtraFeeEntity extends Equatable {
  final int? id;
  final int studentId;
  final String description;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final DateTime? dueDate;

  const ExtraFeeEntity({
    this.id,
    required this.studentId,
    required this.description,
    required this.totalAmount,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.status = 'unpaid',
    this.dueDate,
  });

  @override
  List<Object?> get props => [
    id,
    studentId,
    description,
    totalAmount,
    paidAmount,
    remainingAmount,
    status,
    dueDate,
  ];
}
