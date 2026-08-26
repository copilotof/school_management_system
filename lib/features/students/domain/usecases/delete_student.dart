import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/students/domain/repositories/student_repository.dart';

class DeleteStudent {
  final StudentRepository repository;
  const DeleteStudent({required this.repository});

  Future<Either<Failure, bool>> call(int id) async {
    return await repository.deleteStudent(id);
  }
}
