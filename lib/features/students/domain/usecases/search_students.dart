import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/domain/repositories/student_repository.dart';

class SearchStudents {
  final StudentRepository repository;
  const SearchStudents({required this.repository});

  Future<Either<Failure, List<StudentEntity>>> call(String query) async {
    return await repository.searchStudents(query);
  }
}
