import 'package:drift/drift.dart';
import 'package:school_management_system/features/students/data/models/student_mapper.dart';
import 'package:school_management_system/features/students/data/sources/student_local_source.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/domain/repositories/student_repository.dart';

/// 📁 تنفيذ مستودع الطالب

class StudentRepositoryImpl implements StudentRepository {
  final StudentLocalDataSource localDataSource;

  StudentRepositoryImpl({required this.localDataSource});

  @override
  Future<List<StudentEntity>> getAllStudents() async {
    final rows = await localDataSource.getAllStudents();
    return rows.map((r) => r.toEntity()).toList();
  }

  @override
  Stream<List<StudentEntity>> watchAllStudents() {
    return localDataSource.watchAllStudents().map(
      (rows) => rows.map((r) => r.toEntity()).toList(),
    );
  }

  @override
  Future<StudentEntity?> getStudentById(int id) async {
    final row = await localDataSource.getStudentById(id);
    return row?.toEntity();
  }

  @override
  Future<StudentEntity?> getStudentByCode(String studentCode) async {
    final row = await localDataSource.getStudentByCode(studentCode);
    return row?.toEntity();
  }

  @override
  Future<List<StudentEntity>> searchStudents(String query) async {
    final rows = await localDataSource.searchStudents(query);
    return rows.map((r) => r.toEntity()).toList();
  }

  @override
  Future<int> createStudent(StudentEntity student) async {
    final companion = StudentMapper.fromEntity(student);
    return await localDataSource.createStudent(companion);
  }

  @override
  Future<bool> updateStudent(StudentEntity student) async {
    // يجب جلب الصف الحالي أولاً للتحديث
    final currentRow = await localDataSource.getStudentById(student.id!);
    if (currentRow == null) return false;

    // تحديث الصف
    final updatedRow = currentRow.copyWith(
      schoolId: student.schoolId,
      guardianId: Value(student.guardianId),
      studentCode: student.studentCode,
      firstName: student.firstName,
      lastName: student.lastName,
      dateOfBirth: Value(student.dateOfBirth),
      gender: Value(student.gender),
      address: Value(student.address),
      photoPath: Value(student.photoPath),
      status: student.status,
      notes: Value(student.notes),
      updatedAt: DateTime.now(),
    );

    return await localDataSource.updateStudent(updatedRow);
  }

  @override
  Future<int> deleteStudent(int id) async {
    return await localDataSource.deleteStudent(id);
  }

  @override
  Future<int> getStudentsCount() async {
    return await localDataSource.getStudentsCount();
  }
}
