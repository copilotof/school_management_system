import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/homework/data/models/homework_mapper.dart';
import 'package:school_management_system/features/homework/data/sources/homework_local_source.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_entity.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_submission_entity.dart';
import 'package:school_management_system/features/homework/domain/repositories/homework_repository.dart';

import '../../../../core/database/app_database.dart';
import '../../../attendance/data/models/attendance_mapper.dart';
import '../../../attendance/domain/entities/session_entity.dart';

class HomeworkRepositoryImpl implements HomeworkRepository {
  final HomeworkLocalDataSource localDataSource;
  final AppDatabase db;
  HomeworkRepositoryImpl({required this.localDataSource, required this.db});

  // ====== الواجبات ======
  @override
  Future<Either<Failure, List<HomeworkEntity>>> getAllHomeworks() async {
    try {
      final rows = await localDataSource.getAllHomeworks();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, List<HomeworkEntity>>> getHomeworksByGroup(
    int groupId,
  ) async {
    try {
      final rows = await localDataSource.getHomeworksByGroup(groupId);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, List<HomeworkEntity>>> getHomeworksBySession(
    int sessionId,
  ) async {
    try {
      final rows = await localDataSource.getHomeworksBySession(sessionId);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, HomeworkEntity?>> getHomeworkById(int id) async {
    try {
      final row = await localDataSource.getHomeworkById(id);
      return Right(row?.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createHomework(HomeworkEntity homework) async {
    try {
      final companion = HomeworkMapper.fromEntity(homework);
      final id = await localDataSource.createHomework(companion);

      // ✅ إنشاء تسليمات لكل طلاب الفوج (تلقائياً)
      await localDataSource.createSubmissionsForGroup(
        homeworkId: id,
        groupId: homework.groupId,
      );

      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateHomework(HomeworkEntity homework) async {
    try {
      final row = await localDataSource.getHomeworkById(homework.id!);
      if (row == null) return const Left(NotFoundFailure('الواجب غير موجود'));
      final updated = row.copyWith(
        title: homework.title,
        description: homework.description,
        dueDate: homework.dueDate,
        isCompleted: homework.isCompleted,
        notes: Value(homework.notes),
        updatedAt: DateTime.now(),
      );
      return Right(await localDataSource.updateHomework(updated));
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteHomework(int id) async {
    try {
      return Right(await localDataSource.deleteHomework(id) > 0);
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  // ====== التسليمات ======
  @override
  Future<Either<Failure, List<HomeworkSubmissionEntity>>>
  getSubmissionsByHomework(int homeworkId) async {
    try {
      final rows = await localDataSource.getSubmissionsByHomework(homeworkId);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateSubmission(
    HomeworkSubmissionEntity submission,
  ) async {
    try {
      final row = await localDataSource.getSubmission(
        submission.homeworkId,
        submission.studentId,
      );
      if (row == null) return const Left(NotFoundFailure('التسليم غير موجود'));
      final updated = row.copyWith(
        status: submission.status,
        submittedAt: Value(submission.submittedAt),
        notes: Value(submission.notes),
        updatedAt: DateTime.now(),
      );
      return Right(await localDataSource.updateSubmission(updated));
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> createSubmissionsForGroup({
    required int homeworkId,
    required int groupId,
  }) async {
    try {
      await localDataSource.createSubmissionsForGroup(
        homeworkId: homeworkId,
        groupId: groupId,
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SessionEntity>>> getUpcomingSessions({
    required int groupId,
    required DateTime after,
  }) async {
    try {
      final rows =
          await (db.select(db.sessions)
                ..where(
                  (t) =>
                      t.groupId.equals(groupId) &
                      t.sessionDate.isBiggerThanValue(after) &
                      t.status.equals('scheduled'),
                )
                ..orderBy([(t) => OrderingTerm(expression: t.sessionDate)]))
              .get();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب الحصص: $e'));
    }
  }

  @override
  Future<Either<Failure, List<HomeworkEntity>>>
  getHomeworksByGroupAndDateRange({
    required int groupId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final rows = await localDataSource.getHomeworksByGroupAndDateRange(
        groupId: groupId,
        from: from,
        to: to,
      );
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }
}
