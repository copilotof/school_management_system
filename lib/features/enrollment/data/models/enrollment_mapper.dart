import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/enrollment/domain/entities/enrollment_entity.dart';

/// 📁 محول التسجيل

extension EnrollmentMapper on Enrollment {
  EnrollmentEntity toEntity({String? studentName, String? groupName}) {
    debugPrint(
      '🟣 Mapper.toEntity: id=$id, studentId=$studentId, groupId=$groupId',
    );
    return EnrollmentEntity(
      id: id,
      studentId: studentId,
      groupId: groupId, // ✅ موجود الآن
      studentName: studentName,
      groupName: groupName,
      enrollmentDate: enrollmentDate,
      registrationFee: registrationFee,
      status: status,
      notes: notes,
      createdAt: createdAt,
    );
  }

  static EnrollmentsCompanion fromEntity(EnrollmentEntity entity) {
    debugPrint(
      '🟣 Mapper.fromEntity: studentId=${entity.studentId}, groupId=${entity.groupId}',
    );
    return EnrollmentsCompanion.insert(
      studentId: entity.studentId,
      groupId: entity.groupId, // ✅
      enrollmentDate: Value(entity.enrollmentDate),
      registrationFee: Value(entity.registrationFee),
      status: Value(entity.status),
      notes: Value(entity.notes),
    );
  }
}
