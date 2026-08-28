import 'package:equatable/equatable.dart';

/// 📁 كيان المعلم

class TeacherEntity extends Equatable {
  final int? id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? specialization;
  final DateTime? hireDate;
  final bool isActive;
  final DateTime? createdAt;

  const TeacherEntity({
    this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.specialization,
    this.hireDate,
    this.isActive = true,
    this.createdAt,
  });

  TeacherEntity copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? email,
    String? specialization,
    DateTime? hireDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return TeacherEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      specialization: specialization ?? this.specialization,
      hireDate: hireDate ?? this.hireDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, fullName, phone, email, specialization, hireDate, isActive, createdAt];
}