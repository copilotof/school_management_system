import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/teachers/domain/entities/teacher_entity.dart';
import 'package:school_management_system/features/teachers/domain/repositories/teacher_repository.dart';

class GetAllTeachers {
  final TeacherRepository repository;
  const GetAllTeachers({required this.repository});

  Future<Either<Failure, List<TeacherEntity>>> call() async {
    return await repository.getAllTeachers();
  }
}