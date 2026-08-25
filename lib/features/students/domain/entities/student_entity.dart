import 'package:equatable/equatable.dart';

/// 📁 كيان الطالب (Entity)
/// الاسم موحد: StudentEntity

class StudentEntity extends Equatable {
  final int? id;
  final int schoolId;
  final int? guardianId;
  final String studentCode;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? photoPath;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentEntity({
    this.id,
    this.schoolId = 1,
    this.guardianId,
    required this.studentCode,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.photoPath,
    this.status = 'active',
    this.notes,
    this.createdAt,
    this.updatedAt,
    required String phone,
  });

  String get fullName => '$firstName $lastName';
  bool get isActive => status == 'active';

  StudentEntity copyWith({
    int? id,
    int? schoolId,
    int? guardianId,
    String? studentCode,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? photoPath,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      guardianId: guardianId ?? this.guardianId,
      studentCode: studentCode ?? this.studentCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      photoPath: photoPath ?? this.photoPath,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phone: '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    guardianId,
    studentCode,
    firstName,
    lastName,
    dateOfBirth,
    gender,
    address,
    photoPath,
    status,
    notes,
    createdAt,
    updatedAt,
  ];
}
