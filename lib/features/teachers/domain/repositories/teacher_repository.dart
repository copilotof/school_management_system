import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/teachers/domain/entities/teacher_entity.dart';

/// 📁 واجهة مستودع المعلمين

abstract class TeacherRepository {
  Future<Either<Failure, List<TeacherEntity>>> getAllTeachers();
  Future<Either<Failure, TeacherEntity?>> getTeacherById(int id);
  Future<Either<Failure, List<TeacherEntity>>> searchTeachers(String query);
  Future<Either<Failure, int>> createTeacher(TeacherEntity teacher);
  Future<Either<Failure, bool>> updateTeacher(TeacherEntity teacher);
  Future<Either<Failure, bool>> deleteTeacher(int id);
  Future<Either<Failure, int>> getTeachersCount();
}