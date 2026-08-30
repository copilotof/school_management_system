import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/grades/domain/entities/grade_entity.dart';

/// 📁 محول الصف

extension GradeMapper on Grade {
  GradeEntity toEntity() {
    return GradeEntity(
      id: id,
      levelId: academicLevelId,
      name: name,
      orderIndex: orderIndex,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  static GradesCompanion fromEntity(GradeEntity entity) {
    return GradesCompanion.insert(
      academicLevelId: Value(entity.levelId),
      name: entity.name,
      orderIndex: Value(entity.orderIndex),
      isActive: Value(entity.isActive),
    );
  }
}
