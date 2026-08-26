import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/domain/repositories/student_repository.dart';

class CreateStudent {
  final StudentRepository repository;
  const CreateStudent({required this.repository});

  Future<Either<Failure, int>> call(StudentEntity student) async {
    return await repository.createStudent(student);
  }
}
