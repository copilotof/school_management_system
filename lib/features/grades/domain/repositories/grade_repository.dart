import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/grades/domain/entities/grade_entity.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';

abstract class GradeRepository {
  Future<Either<Failure, List<GradeEntity>>> getAllGrades();
  Future<Either<Failure, List<GradeEntity>>> getGradesByLevel(int levelId);
  Future<Either<Failure, int>> createGrade(GradeEntity grade);
  Future<Either<Failure, bool>> updateGrade(GradeEntity grade);
  Future<Either<Failure, bool>> deleteGrade(int id);

  // ✅ دوال علاقة الصفوف والمواد
  Future<Either<Failure, List<SubjectEntity>>> getSubjectsByGrade(int gradeId);
  Future<Either<Failure, void>> saveSubjectsForGrade({
    required int gradeId,
    required List<int> subjectIds,
  });
}
