import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

/// 📁 واجهة مستودع الطالب

abstract class StudentRepository {
  Future<List<StudentEntity>> getAllStudents();
  Stream<List<StudentEntity>> watchAllStudents();
  Future<StudentEntity?> getStudentById(int id);
  Future<StudentEntity?> getStudentByCode(String studentCode);
  Future<List<StudentEntity>> searchStudents(String query);
  Future<int> createStudent(StudentEntity student);
  Future<bool> updateStudent(StudentEntity student);
  Future<int> deleteStudent(int id);
  Future<int> getStudentsCount();
}
