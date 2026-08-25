import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';

/// 📁 مصدر البيانات المحلي للطلاب

class StudentLocalDataSource {
  final AppDatabase db;

  StudentLocalDataSource({required this.db});

  /// جلب كل الطلاب
  Future<List<Student>> getAllStudents() async {
    return await (db.select(db.students)..orderBy([
          (t) => OrderingTerm(expression: t.lastName),
          (t) => OrderingTerm(expression: t.firstName),
        ]))
        .get();
  }

  /// مراقبة كل الطلاب (Stream)
  Stream<List<Student>> watchAllStudents() {
    return (db.select(db.students)..orderBy([
          (t) => OrderingTerm(expression: t.lastName),
          (t) => OrderingTerm(expression: t.firstName),
        ]))
        .watch();
  }

  /// جلب طالب بالمعرف
  Future<Student?> getStudentById(int id) async {
    return await (db.select(
      db.students,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// جلب طالب بالرقم
  Future<Student?> getStudentByCode(String studentCode) async {
    return await (db.select(
      db.students,
    )..where((t) => t.studentCode.equals(studentCode))).getSingleOrNull();
  }

  /// البحث
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

  /// إنشاء
  Future<int> createStudent(StudentsCompanion student) async {
    return await db.into(db.students).insert(student);
  }

  /// تحديث
  Future<bool> updateStudent(Student student) async {
    return await db.update(db.students).replace(student);
  }

  /// حذف
  Future<int> deleteStudent(int id) async {
    return await (db.delete(db.students)..where((t) => t.id.equals(id))).go();
  }

  /// عدد الطلاب (تصحيح: استخدام getSingle)
  Future<int> getStudentsCount() async {
    final countQuery = db.selectOnly(db.students)
      ..addColumns([db.students.id.count()]);
    final row = await countQuery.getSingle();
    return row.read(db.students.id.count()) ?? 0;
  }
}
