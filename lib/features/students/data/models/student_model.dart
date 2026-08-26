import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

/// 📁 نموذج الطالب - يمثل الطالب في طبقة البيانات
/// يضيف دوال التحويل من/إلى JSON ومن/إلى Drift

class StudentModel {
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

  const StudentModel({
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

  /// تحويل من Entity إلى Model
  factory StudentModel.fromEntity(StudentEntity entity) {
    return StudentModel(
      id: entity.id,
      studentCode: entity.studentCode,
      firstName: entity.firstName,
      lastName: entity.lastName,
      dateOfBirth: entity.dateOfBirth,
      gender: entity.gender,
      address: entity.address,
      phone: entity.phone,
      photoPath: entity.photoPath,
      status: entity.status,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// تحويل إلى Entity
  StudentEntity toEntity() {
    return StudentEntity(
      id: id,
      studentCode: studentCode,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      address: address,
      phone: phone ?? '',
      photoPath: photoPath,
      status: status,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// تحويل من JSON
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as int?,
      studentCode: json['studentCode'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      photoPath: json['photoPath'] as String?,
      status: json['status'] as String? ?? 'active',
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentCode': studentCode,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'phone': phone,
      'photoPath': photoPath,
      'status': status,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
