import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/attendance/domain/entities/attendance_entity.dart';
import 'package:school_management_system/features/attendance/domain/entities/session_entity.dart';

/// 📁 محول الحضور
extension AttendanceMapper on AttendanceRecord {
  AttendanceEntity toEntity({String? studentName}) {
    return AttendanceEntity(
      id: id,
      sessionId: sessionId,
      studentId: studentId,
      studentName: studentName,
      status: status,
      checkInTime: checkInTime,
      recordedBy: recordedBy,
      notes: notes,
      createdAt: createdAt,
    );
  }

  static AttendanceCompanion fromEntity(AttendanceEntity entity) {
    return AttendanceCompanion.insert(
      sessionId: entity.sessionId,
      studentId: entity.studentId,
      status: entity.status,
      checkInTime: Value(entity.checkInTime),
      recordedBy: Value(entity.recordedBy),
      notes: Value(entity.notes),
    );
  }
}

/// 📁 محول الحصة
extension SessionMapper on Session {
  SessionEntity toEntity({
    String? groupName,
    int? studentsCount,
    int? presentCount,
  }) {
    return SessionEntity(
      id: id,
      groupId: groupId,
      groupName: groupName,
      templateId: templateId,
      sessionDate: sessionDate,
      startTime: startTime,
      endTime: endTime,
      type: type,
      status: status,
      lessonTopic: lessonTopic,
      teacherNotes: teacherNotes,
      homework: homework,
      cancelReason: cancelReason,
      isPaid: isPaid,
      price: price,
      paymentStatus: paymentStatus,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      studentsCount: studentsCount,
      presentCount: presentCount,
      createdAt: createdAt,
    );
  }

  static SessionsCompanion fromEntity(SessionEntity entity) {
    return SessionsCompanion.insert(
      groupId: entity.groupId,
      templateId: Value(entity.templateId),
      sessionDate: entity.sessionDate,
      startTime: entity.startTime,
      endTime: entity.endTime,
      type: Value(entity.type),
      status: Value(entity.status),
      lessonTopic: Value(entity.lessonTopic),
      teacherNotes: Value(entity.teacherNotes),
      homework: Value(entity.homework),
      cancelReason: Value(entity.cancelReason),
      isPaid: Value(entity.isPaid),
      price: Value(entity.price),
      paymentStatus: Value(entity.paymentStatus),
      paidAmount: Value(entity.paidAmount),
      remainingAmount: Value(entity.remainingAmount),
    );
  }
}
