import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';
import 'package:school_management_system/features/subjects/domain/repositories/subject_repository.dart';

class UpdateSubject {
  final SubjectRepository repository;
  const UpdateSubject({required this.repository});

  Future<Either<Failure, bool>> call(SubjectEntity subject) async {
    return await repository.updateSubject(subject);
  }
}
