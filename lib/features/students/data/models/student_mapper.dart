import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

/// 📁 محول الطالب - يحول بين Drift Row و Entity

extension StudentMapper on Student {
  /// من Drift Row إلى Entity
  StudentEntity toEntity() {
    return StudentEntity(
      id: id,
      studentCode: studentCode,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      address: address,
      phone: phone,
      photoPath: photoPath,
      status: status,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// من Entity إلى Drift Companion
  static StudentsCompanion fromEntity(StudentEntity entity) {
    return StudentsCompanion.insert(
      studentCode: entity.studentCode,
      firstName: entity.firstName,
      lastName: entity.lastName,
      dateOfBirth: Value(entity.dateOfBirth),
      gender: Value(entity.gender),
      address: Value(entity.address),
      phone: Value(entity.phone),
      photoPath: Value(entity.photoPath),
      status: Value(entity.status),
      notes: Value(entity.notes),
    );
  }
}
