import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/attendance/domain/entities/schedule_template_entity.dart';

/// 📁 محول القالب الأسبوعي
extension ScheduleTemplateMapper on ScheduleTemplate {
  ScheduleTemplateEntity toEntity() {
    return ScheduleTemplateEntity(
      id: id,
      groupId: groupId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      location: location,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  static ScheduleTemplatesCompanion fromEntity(ScheduleTemplateEntity entity) {
    return ScheduleTemplatesCompanion.insert(
      groupId: entity.groupId,
      dayOfWeek: entity.dayOfWeek,
      startTime: entity.startTime,
      endTime: entity.endTime,
      location: Value(entity.location),
      isActive: Value(entity.isActive),
    );
  }
}
