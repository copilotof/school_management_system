import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/teachers/domain/entities/teacher_entity.dart';

/// 📁 محول المعلم

extension TeacherMapper on Teacher {
  TeacherEntity toEntity() {
    return TeacherEntity(
      id: id,
      fullName: fullName,
      phone: phone,
      email: email,
      specialization: specialization,
      hireDate: hireDate,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  static TeachersCompanion fromEntity(TeacherEntity entity) {
    return TeachersCompanion.insert(
      fullName: entity.fullName,
      phone: Value(entity.phone),
      email: Value(entity.email),
      specialization: Value(entity.specialization),
      hireDate: Value(entity.hireDate),
      isActive: Value(entity.isActive),
    );
  }
}