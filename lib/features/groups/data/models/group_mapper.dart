import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';

extension GroupMapper on Group {
  GroupEntity toEntity() {
    return GroupEntity(
      id: id,
      name: name,
      subjectId: subjectId,
      teacherId: teacherId,
      academicLevelId: academicLevelId,
      gradeId: gradeId,
      maxStudents: maxStudents,
      monthlyFee: monthlyFee,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  static GroupsCompanion fromEntity(GroupEntity entity) {
    return GroupsCompanion.insert(
      name: entity.name,
      subjectId: Value(entity.subjectId),
      teacherId: Value(entity.teacherId),
      academicLevelId: Value(entity.academicLevelId),
      gradeId: Value(entity.gradeId),
      maxStudents: Value(entity.maxStudents),
      monthlyFee: Value(entity.monthlyFee),
      isActive: Value(entity.isActive),
    );
  }
}
