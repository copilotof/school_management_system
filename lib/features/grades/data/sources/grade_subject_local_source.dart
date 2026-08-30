import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';

/// 📁 مصدر بيانات علاقة الصفوف والمواد

class GradeSubjectLocalDataSource {
  final AppDatabase db;

  GradeSubjectLocalDataSource({required this.db});

  /// جلب المواد المرتبطة بصف معين
  Future<List<Subject>> getSubjectsByGrade(int gradeId) async {
    final query = db.select(db.gradeSubjects)
      ..where((t) => t.gradeId.equals(gradeId));

    final rows = await query.get();
    final subjectIds = rows.map((r) => r.subjectId).toList();

    if (subjectIds.isEmpty) return [];

    return await (db.select(
      db.subjects,
    )..where((t) => t.id.isIn(subjectIds))).get();
  }

  /// جلب الصفوف المرتبطة بمادة معينة
  Future<List<Grade>> getGradesBySubject(int subjectId) async {
    final query = db.select(db.gradeSubjects)
      ..where((t) => t.subjectId.equals(subjectId));

    final rows = await query.get();
    final gradeIds = rows.map((r) => r.gradeId).toList();

    if (gradeIds.isEmpty) return [];

    return await (db.select(
      db.grades,
    )..where((t) => t.id.isIn(gradeIds))).get();
  }

  /// ربط مادة بصف
  Future<int> linkSubjectToGrade({
    required int gradeId,
    required int subjectId,
  }) async {
    return await db
        .into(db.gradeSubjects)
        .insert(
          GradeSubjectsCompanion.insert(gradeId: gradeId, subjectId: subjectId),
        );
  }

  /// إلغاء ربط مادة بصف
  Future<int> unlinkSubjectFromGrade({
    required int gradeId,
    required int subjectId,
  }) async {
    return await (db.delete(db.gradeSubjects)..where(
          (t) => t.gradeId.equals(gradeId) & t.subjectId.equals(subjectId),
        ))
        .go();
  }

  /// إلغاء ربط كل المواد من صف
  Future<int> unlinkAllSubjectsFromGrade(int gradeId) async {
    return await (db.delete(
      db.gradeSubjects,
    )..where((t) => t.gradeId.equals(gradeId))).go();
  }

  /// حفظ قائمة المواد المرتبطة بصف (استبدال الكل)
  Future<void> saveSubjectsForGrade({
    required int gradeId,
    required List<int> subjectIds,
  }) async {
    await db.transaction(() async {
      // حذف كل الروابط القديمة
      await unlinkAllSubjectsFromGrade(gradeId);
      // إضافة الروابط الجديدة
      for (final subjectId in subjectIds) {
        await linkSubjectToGrade(gradeId: gradeId, subjectId: subjectId);
      }
    });
  }
}
