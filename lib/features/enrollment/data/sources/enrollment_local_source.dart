import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:school_management_system/core/database/app_database.dart';

class EnrollmentLocalDataSource {
  final AppDatabase db;

  EnrollmentLocalDataSource({required this.db});

  Future<List<Enrollment>> getAllEnrollments() async {
    debugPrint('🟡 DataSource.getAllEnrollments: استعلام...');
    final result = await (db.select(db.enrollments)).get();
    debugPrint('🟢 DataSource.getAllEnrollments: ${result.length} صف');
    return result;
  }

  Future<List<Enrollment>> getEnrollmentsByStudent(int studentId) async {
    return await (db.select(
      db.enrollments,
    )..where((t) => t.studentId.equals(studentId))).get();
  }

  Future<List<Enrollment>> getEnrollmentsByGroup(int groupId) async {
    return await (db.select(
      db.enrollments,
    )..where((t) => t.groupId.equals(groupId))).get();
  }

  Future<Enrollment?> getEnrollmentById(int id) async {
    return await (db.select(
      db.enrollments,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> createEnrollment(EnrollmentsCompanion enrollment) async {
    debugPrint('🟡 DataSource.createEnrollment: إدراج...');
    final id = await db.into(db.enrollments).insert(enrollment);
    debugPrint('🟢 DataSource.createEnrollment: id=$id');
    return id;
  }

  Future<bool> updateEnrollment(Enrollment enrollment) async {
    return await db.update(db.enrollments).replace(enrollment);
  }

  Future<int> deleteEnrollment(int id) async {
    debugPrint('🟡 DataSource.deleteEnrollment: id=$id');
    final result = await (db.delete(
      db.enrollments,
    )..where((t) => t.id.equals(id))).go();
    debugPrint('🟢 DataSource.deleteEnrollment: result=$result');
    return result;
  }

  Future<int> getEnrollmentsCount() async {
    final all = await getAllEnrollments();
    return all.length;
  }

  Future<int> getStudentsCountByGroup(int groupId) async {
    final enrollments = await getEnrollmentsByGroup(groupId);
    return enrollments.where((e) => e.status == 'active').length;
  }
}
