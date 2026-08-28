import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';

/// 📁 مصدر بيانات المعلمين المحلي

class TeacherLocalDataSource {
  final AppDatabase db;

  TeacherLocalDataSource({required this.db});

  Future<List<Teacher>> getAllTeachers() async {
    return await (db.select(db.teachers)
          ..orderBy([(t) => OrderingTerm(expression: t.fullName)]))
        .get();
  }

  Future<Teacher?> getTeacherById(int id) async {
    return await (db.select(db.teachers)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<Teacher>> searchTeachers(String query) async {
    final term = '%$query%';
    return await (db.select(db.teachers)
          ..where((t) => t.fullName.like(term) | t.email.like(term)))
        .get();
  }

  Future<int> createTeacher(TeachersCompanion teacher) async {
    return await db.into(db.teachers).insert(teacher);
  }

  Future<bool> updateTeacher(Teacher teacher) async {
    return await db.update(db.teachers).replace(teacher);
  }

  Future<int> deleteTeacher(int id) async {
    return await (db.delete(db.teachers)..where((t) => t.id.equals(id))).go();
  }

  Future<int> getTeachersCount() async {
    final all = await getAllTeachers();
    return all.length;
  }
}