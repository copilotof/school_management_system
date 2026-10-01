import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';

/// 📁 مصدر بيانات الواجبات
class HomeworkLocalDataSource {
  final AppDatabase db;

  HomeworkLocalDataSource({required this.db});

  // ====== الواجبات ======
  Future<List<Homework>> getAllHomeworks() async {
    return await (db.select(db.homeworks)..orderBy([
          (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<List<Homework>> getHomeworksByGroup(int groupId) async {
    return await (db.select(db.homeworks)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<List<Homework>> getHomeworksBySession(int sessionId) async {
    return await (db.select(
      db.homeworks,
    )..where((t) => t.sessionId.equals(sessionId))).get();
  }

  Future<Homework?> getHomeworkById(int id) async {
    return await (db.select(
      db.homeworks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> createHomework(HomeworksCompanion homework) async {
    return await db.into(db.homeworks).insert(homework);
  }

  Future<bool> updateHomework(Homework homework) async {
    return await db.update(db.homeworks).replace(homework);
  }

  Future<int> deleteHomework(int id) async {
    // حذف التسليمات المرتبطة أولاً
    await (db.delete(
      db.homeworkSubmissions,
    )..where((t) => t.homeworkId.equals(id))).go();
    return await (db.delete(db.homeworks)..where((t) => t.id.equals(id))).go();
  }

  // ====== التسليمات ======
  Future<List<HomeworkSubmission>> getSubmissionsByHomework(
    int homeworkId,
  ) async {
    return await (db.select(
      db.homeworkSubmissions,
    )..where((t) => t.homeworkId.equals(homeworkId))).get();
  }

  Future<HomeworkSubmission?> getSubmission(
    int homeworkId,
    int studentId,
  ) async {
    return await (db.select(db.homeworkSubmissions)..where(
          (t) =>
              t.homeworkId.equals(homeworkId) & t.studentId.equals(studentId),
        ))
        .getSingleOrNull();
  }

  Future<int> createSubmission(HomeworkSubmissionsCompanion submission) async {
    return await db.into(db.homeworkSubmissions).insert(submission);
  }

  Future<bool> updateSubmission(HomeworkSubmission submission) async {
    return await db.update(db.homeworkSubmissions).replace(submission);
  }

  /// ✅ إنشاء تسليمات لكل طلاب الفوج
  Future<void> createSubmissionsForGroup({
    required int homeworkId,
    required int groupId,
    List<int>? selectedStudentIds,
  }) async {
    List<int> studentIds;

    if (selectedStudentIds != null && selectedStudentIds.isNotEmpty) {
      // فردي: فقط الطلاب المحددين
      studentIds = selectedStudentIds;
    } else {
      // جماعي: كل طلاب الفوج
      final enrollments =
          await (db.select(db.enrollments)..where(
                (t) => t.groupId.equals(groupId) & t.status.equals('active'),
              ))
              .get();
      studentIds = enrollments.map((e) => e.studentId).toList();
    }

    for (final studentId in studentIds) {
      final existing = await getSubmission(homeworkId, studentId);
      if (existing != null) continue;

      await db
          .into(db.homeworkSubmissions)
          .insert(
            HomeworkSubmissionsCompanion.insert(
              homeworkId: homeworkId,
              studentId: studentId,
              status: const Value('pending'),
            ),
          );
    }
  }

  Future<List<Homework>> getHomeworksByGroupAndDateRange({
    required int groupId,
    required DateTime from,
    required DateTime to,
  }) async {
    return await (db.select(db.homeworks)
          ..where(
            (t) =>
                t.groupId.equals(groupId) &
                t.dueDate.isBiggerOrEqualValue(from) &
                t.dueDate.isSmallerOrEqualValue(to),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
          ]))
        .get();
  }
}
