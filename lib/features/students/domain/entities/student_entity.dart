import 'package:equatable/equatable.dart';

/// 📁 كيان الطالب - النسخة الكاملة

class StudentEntity extends Equatable {
  final int? id;
  final String studentCode;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? phone;
  final String? photoPath;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentEntity({
    this.id,
    required this.studentCode,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.phone,
    this.photoPath,
    this.status = 'active',
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';
  bool get isActive => status == 'active';

  StudentEntity copyWith({
    int? id,
    String? studentCode,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? phone,
    String? photoPath,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentEntity(
      id: id ?? this.id,
      studentCode: studentCode ?? this.studentCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      photoPath: photoPath ?? this.photoPath,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    studentCode,
    firstName,
    lastName,
    dateOfBirth,
    gender,
    address,
    phone,
    photoPath,
    status,
    notes,
    createdAt,
    updatedAt,
  ];
}
