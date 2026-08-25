import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

/// 📁 محول (Mapper)
/// يحول بين Drift Row و Entity

extension StudentMapper on Student {
  /// من Drift Row إلى Entity
  StudentEntity toEntity() {
    return StudentEntity(
      id: id,
      schoolId: schoolId,
      guardianId: guardianId,
      studentCode: studentCode,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      address: address,
      photoPath: photoPath,
      status: status,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      phone: '',
    );
  }

  /// من Entity إلى Drift Companion (لإدخال بيانات جديدة)
  static StudentsCompanion fromEntity(StudentEntity entity) {
    return StudentsCompanion.insert(
      schoolId: Value(entity.schoolId),
      guardianId: Value(entity.guardianId),
      studentCode: entity.studentCode,
      firstName: entity.firstName,
      lastName: entity.lastName,
      dateOfBirth: Value(entity.dateOfBirth),
      gender: Value(entity.gender),
      address: Value(entity.address),
      photoPath: Value(entity.photoPath),
      status: Value(entity.status),
      notes: Value(entity.notes),
    );
  }
}
