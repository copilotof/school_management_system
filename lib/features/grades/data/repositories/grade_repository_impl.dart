import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/grades/data/models/grade_mapper.dart';
import 'package:school_management_system/features/grades/data/sources/grade_local_source.dart';
import 'package:school_management_system/features/grades/domain/entities/grade_entity.dart';
import 'package:school_management_system/features/grades/domain/repositories/grade_repository.dart';

import '../../../subjects/data/models/subject_mapper.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../sources/grade_subject_local_source.dart';

class GradeRepositoryImpl implements GradeRepository {
  final GradeLocalDataSource localDataSource;
  final GradeSubjectLocalDataSource gradeSubjectLocalDataSource;

  GradeRepositoryImpl({
    required this.localDataSource,
    required this.gradeSubjectLocalDataSource,
  });

  @override
  Future<Either<Failure, List<GradeEntity>>> getAllGrades() async {
    try {
      final rows = await localDataSource.getAllGrades();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب الصفوف: $e'));
    }
  }

  @override
  Future<Either<Failure, List<GradeEntity>>> getGradesByLevel(
    int levelId,
  ) async {
    try {
      final rows = await localDataSource.getGradesByLevel(levelId);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب الصفوف: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createGrade(GradeEntity grade) async {
    try {
      final companion = GradeMapper.fromEntity(grade);
      return Right(await localDataSource.createGrade(companion));
    } catch (e) {
      return Left(DatabaseFailure('فشل في إنشاء الصف: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateGrade(GradeEntity grade) async {
    try {
      final row = await localDataSource.getGradeById(grade.id!);
      if (row == null) return const Left(NotFoundFailure('الصف غير موجود'));
      final updated = row.copyWith(
        academicLevelId: Value(grade.levelId),
        name: grade.name,
        orderIndex: grade.orderIndex,
        isActive: grade.isActive,
      );
      return Right(await localDataSource.updateGrade(updated));
    } catch (e) {
      return Left(DatabaseFailure('فشل في تحديث الصف: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteGrade(int id) async {
    try {
      return Right(await localDataSource.deleteGrade(id) > 0);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حذف الصف: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SubjectEntity>>> getSubjectsByGrade(
    int gradeId,
  ) async {
    try {
      final rows = await gradeSubjectLocalDataSource.getSubjectsByGrade(
        gradeId,
      );
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب المواد المرتبطة: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSubjectsForGrade({
    required int gradeId,
    required List<int> subjectIds,
  }) async {
    try {
      await gradeSubjectLocalDataSource.saveSubjectsForGrade(
        gradeId: gradeId,
        subjectIds: subjectIds,
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حفظ المواد المرتبطة: $e'));
    }
  }
}
