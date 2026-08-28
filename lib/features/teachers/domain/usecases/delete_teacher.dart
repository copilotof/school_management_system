import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/teachers/domain/repositories/teacher_repository.dart';

class DeleteTeacher {
  final TeacherRepository repository;
  const DeleteTeacher({required this.repository});

  Future<Either<Failure, bool>> call(int id) async {
    return await repository.deleteTeacher(id);
  }
}