import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/subjects/domain/repositories/subject_repository.dart';

class DeleteSubject {
  final SubjectRepository repository;
  const DeleteSubject({required this.repository});

  Future<Either<Failure, bool>> call(int id) async {
    return await repository.deleteSubject(id);
  }
}
