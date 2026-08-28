import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/teachers/domain/entities/teacher_entity.dart';
import 'package:school_management_system/features/teachers/domain/repositories/teacher_repository.dart';

class CreateTeacher {
  final TeacherRepository repository;
  const CreateTeacher({required this.repository});

  Future<Either<Failure, int>> call(TeacherEntity teacher) async {
    return await repository.createTeacher(teacher);
  }
}