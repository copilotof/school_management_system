import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';

/// 📁 مصدر بيانات الطلاب المحلي

class StudentLocalDataSource {
  final AppDatabase db;

  StudentLocalDataSource({required this.db});

  Future<List<Student>> getAllStudents() async {
    return await (db.select(db.students)..orderBy([
          (t) => OrderingTerm(expression: t.lastName),
          (t) => OrderingTerm(expression: t.firstName),
        ]))
        .get();
  }

  Stream<List<Student>> watchAllStudents() {
    return (db.select(db.students)..orderBy([
          (t) => OrderingTerm(expression: t.lastName),
          (t) => OrderingTerm(expression: t.firstName),
        ]))
        .watch();
  }

  Future<Student?> getStudentById(int id) async {
    return await (db.select(
      db.students,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Student?> getStudentByCode(String studentCode) async {
    return await (db.select(
      db.students,
    )..where((t) => t.studentCode.equals(studentCode))).getSingleOrNull();
  }

  Future<List<Student>> searchStudents(String query) async {
    final term = '%$query%';
    return await (db.select(db.students)..where(
          (t) =>
              t.firstName.like(term) |
              t.lastName.like(term) |
              t.studentCode.like(term),
        ))
        .get();
  }

  Future<int> createStudent(StudentsCompanion student) async {
    return await db.into(db.students).insert(student);
  }

  Future<bool> updateStudent(Student student) async {
    return await db.update(db.students).replace(student);
  }

  Future<int> deleteStudent(int id) async {
    return await (db.delete(db.students)..where((t) => t.id.equals(id))).go();
  }

  /// ✅ إضافة دالة حذف كل الطلاب
  Future<int> deleteAllStudents() async {
    return await db.delete(db.students).go();
  }

  Future<int> getStudentsCount() async {
    final allStudents = await getAllStudents();
    return allStudents.length;
  }
}
