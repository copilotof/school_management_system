import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

/// 📁 واجهة مستودع الطالب - النسخة الصحيحة مع Either

abstract class StudentRepository {
  Future<Either<Failure, List<StudentEntity>>> getAllStudents();
  Stream<Either<Failure, List<StudentEntity>>> watchAllStudents();
  Future<Either<Failure, StudentEntity?>> getStudentById(int id);
  Future<Either<Failure, StudentEntity?>> getStudentByCode(String studentCode);
  Future<Either<Failure, List<StudentEntity>>> searchStudents(String query);
  Future<Either<Failure, int>> createStudent(StudentEntity student);
  Future<Either<Failure, bool>> updateStudent(StudentEntity student);
  Future<Either<Failure, bool>> deleteStudent(int id);
  Future<Either<Failure, int>> deleteAllStudents();
  Future<Either<Failure, int>> getStudentsCount();
}
