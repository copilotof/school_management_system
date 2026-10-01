import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_entity.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_submission_entity.dart';

extension HomeworkMapper on Homework {
  HomeworkEntity toEntity() {
    return HomeworkEntity(
      id: id,
      sessionId: sessionId,
      targetSessionId: targetSessionId,
      groupId: groupId,
      title: title,
      description: description,
      dueDate: dueDate,
      isCompleted: isCompleted,
      notes: notes,
      createdAt: createdAt,
    );
  }

  static HomeworksCompanion fromEntity(HomeworkEntity entity) {
    return HomeworksCompanion.insert(
      sessionId: entity.sessionId,
      targetSessionId: Value(entity.targetSessionId),
      groupId: entity.groupId,
      title: entity.title,
      description: entity.description,
      dueDate: entity.dueDate,
      isCompleted: Value(entity.isCompleted),
      notes: Value(entity.notes),
    );
  }
}

extension HomeworkSubmissionMapper on HomeworkSubmission {
  HomeworkSubmissionEntity toEntity({String? studentName}) {
    return HomeworkSubmissionEntity(
      id: id,
      homeworkId: homeworkId,
      studentId: studentId,
      studentName: studentName,
      status: status,
      submittedAt: submittedAt,
      notes: notes,
      createdAt: createdAt,
    );
  }

  static HomeworkSubmissionsCompanion fromEntity(
    HomeworkSubmissionEntity entity,
  ) {
    return HomeworkSubmissionsCompanion.insert(
      homeworkId: entity.homeworkId,
      studentId: entity.studentId,
      status: Value(entity.status),
      submittedAt: Value(entity.submittedAt),
      notes: Value(entity.notes),
    );
  }
}
