import 'package:equatable/equatable.dart';

/// 📁 كيان التسجيل - يربط الطالب بالفوج

class EnrollmentEntity extends Equatable {
  final int? id;
  final int studentId;
  final int groupId;
  final String? studentName; // للعرض
  final String? groupName; // للعرض
  final DateTime enrollmentDate;
  final double registrationFee;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  const EnrollmentEntity({
    this.id,
    required this.studentId,
    required this.groupId,
    this.studentName,
    this.groupName,
    required this.enrollmentDate,
    this.registrationFee = 0,
    this.status = 'active',
    this.notes,
    this.createdAt,
  });

  EnrollmentEntity copyWith({
    int? id,
    int? studentId,
    int? groupId,
    String? studentName,
    String? groupName,
    DateTime? enrollmentDate,
    double? registrationFee,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return EnrollmentEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      groupId: groupId ?? this.groupId,
      studentName: studentName ?? this.studentName,
      groupName: groupName ?? this.groupName,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      registrationFee: registrationFee ?? this.registrationFee,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        groupId,
        studentName,
        groupName,
        enrollmentDate,
        registrationFee,
        status,
        notes,
        createdAt,
      ];
}