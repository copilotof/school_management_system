import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/domain/repositories/student_repository.dart';

class UpdateStudent {
  final StudentRepository repository;
  const UpdateStudent({required this.repository});

  Future<Either<Failure, bool>> call(StudentEntity student) async {
    return await repository.updateStudent(student);
  }
}
