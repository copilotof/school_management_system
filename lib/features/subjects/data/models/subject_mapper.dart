import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';

/// 📁 محول المادة الدراسية
/// يحول بين Drift Row و Entity

extension SubjectMapper on Subject {
  /// من Drift Row إلى Entity
  SubjectEntity toEntity() {
    return SubjectEntity(
      id: id,
      name: name,
      code: code,
      description: description,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  /// من Entity إلى Drift Companion
  static SubjectsCompanion fromEntity(SubjectEntity entity) {
    return SubjectsCompanion.insert(
      name: entity.name,
      code: Value(entity.code),
      description: Value(entity.description),
      isActive: Value(entity.isActive),
    );
  }
}
