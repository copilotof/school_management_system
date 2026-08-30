import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';

/// 📁 مصدر بيانات الصفوف

class GradeLocalDataSource {
  final AppDatabase db;

  GradeLocalDataSource({required this.db});

  Future<List<Grade>> getAllGrades() async {
    return await (db.select(db.grades)..orderBy([
          (t) => OrderingTerm(expression: t.academicLevelId),
          (t) => OrderingTerm(expression: t.orderIndex),
        ]))
        .get();
  }

  Future<List<Grade>> getGradesByLevel(int levelId) async {
    return await (db.select(db.grades)
          ..where((t) => t.academicLevelId.equals(levelId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .get();
  }

  Future<Grade?> getGradeById(int id) async {
    return await (db.select(
      db.grades,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> createGrade(GradesCompanion grade) async {
    return await db.into(db.grades).insert(grade);
  }

  Future<bool> updateGrade(Grade grade) async {
    return await db.update(db.grades).replace(grade);
  }

  Future<int> deleteGrade(int id) async {
    return await (db.delete(db.grades)..where((t) => t.id.equals(id))).go();
  }
}
