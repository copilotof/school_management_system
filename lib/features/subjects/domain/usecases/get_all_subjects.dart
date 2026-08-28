import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';
import 'package:school_management_system/features/subjects/domain/repositories/subject_repository.dart';

class GetAllSubjects {
  final SubjectRepository repository;
  const GetAllSubjects({required this.repository});

  Future<Either<Failure, List<SubjectEntity>>> call() async {
    return await repository.getAllSubjects();
  }
}
