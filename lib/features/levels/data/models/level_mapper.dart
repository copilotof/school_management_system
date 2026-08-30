import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/levels/domain/entities/level_entity.dart';

extension LevelMapper on AcademicLevel {
  LevelEntity toEntity() {
    return LevelEntity(
      id: id,
      name: name,
      orderIndex: orderIndex,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  static AcademicLevelsCompanion fromEntity(LevelEntity entity) {
    return AcademicLevelsCompanion.insert(
      name: entity.name,
      orderIndex: Value(entity.orderIndex),
      isActive: Value(entity.isActive),
    );
  }
}
