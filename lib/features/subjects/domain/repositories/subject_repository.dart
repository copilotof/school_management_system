import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';

/// 📁 واجهة مستودع المواد

abstract class SubjectRepository {
  Future<Either<Failure, List<SubjectEntity>>> getAllSubjects();
  Stream<Either<Failure, List<SubjectEntity>>> watchAllSubjects();
  Future<Either<Failure, SubjectEntity?>> getSubjectById(int id);
  Future<Either<Failure, List<SubjectEntity>>> searchSubjects(String query);
  Future<Either<Failure, int>> createSubject(SubjectEntity subject);
  Future<Either<Failure, bool>> updateSubject(SubjectEntity subject);
  Future<Either<Failure, bool>> deleteSubject(int id);
  Future<Either<Failure, int>> getSubjectsCount();
}
