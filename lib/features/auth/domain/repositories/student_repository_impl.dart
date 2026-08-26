import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/students/data/models/student_model.dart';
import 'package:school_management_system/features/students/data/sources/student_local_source.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/domain/repositories/student_repository.dart';

import '../../../students/data/models/student_mapper.dart';

/// 📁 تنفيذ مستودع الطالب
/// يربط بين واجهة المستودع ومصدر البيانات
/// يحول الأخطاء إلى Failure

class StudentRepositoryImpl implements StudentRepository {
  final StudentLocalDataSource localDataSource;

  StudentRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<StudentEntity>>> getAllStudents() async {
    try {
      final rows = await localDataSource.getAllStudents();
      final students = rows
          .map((r) => StudentModel.fromEntity(r.toEntity()).toEntity())
          .toList();
      return Right(students);
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب الطلاب: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<StudentEntity>>> watchAllStudents() {
    return localDataSource
        .watchAllStudents()
        .map<Either<Failure, List<StudentEntity>>>((rows) {
          final students = rows.map((r) => r.toEntity()).toList();
          return Right<Failure, List<StudentEntity>>(students);
        })
        .handleError((e) {
          return Left(DatabaseFailure('فشل في مراقبة الطلاب: $e'));
        });
  }

  @override
  Future<Either<Failure, StudentEntity?>> getStudentById(int id) async {
    try {
      final row = await localDataSource.getStudentById(id);
      return Right(row?.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب الطالب: $e'));
    }
  }

  @override
  Future<Either<Failure, StudentEntity?>> getStudentByCode(
    String studentCode,
  ) async {
    try {
      final row = await localDataSource.getStudentByCode(studentCode);
      return Right(row?.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب الطالب: $e'));
    }
  }

  @override
  Future<Either<Failure, List<StudentEntity>>> searchStudents(
    String query,
  ) async {
    try {
      final rows = await localDataSource.searchStudents(query);
      final students = rows.map((r) => r.toEntity()).toList();
      return Right(students);
    } catch (e) {
      return Left(DatabaseFailure('فشل في البحث: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createStudent(StudentEntity student) async {
    try {
      final model = StudentModel.fromEntity(student);
      final companion = _toCompanion(model);
      final id = await localDataSource.createStudent(companion);
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure('فشل في إنشاء الطالب: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateStudent(StudentEntity student) async {
    try {
      final currentRow = await localDataSource.getStudentById(student.id!);
      if (currentRow == null) {
        return const Left(NotFoundFailure('الطالب غير موجود'));
      }

      final updatedRow = currentRow.copyWith(
        studentCode: student.studentCode,
        firstName: student.firstName,
        lastName: student.lastName,
        dateOfBirth: Value(student.dateOfBirth),
        gender: Value(student.gender),
        address: Value(student.address),
        phone: Value(student.phone),
        photoPath: Value(student.photoPath),
        status: student.status,
        notes: Value(student.notes),
        updatedAt: DateTime.now(),
      );

      final result = await localDataSource.updateStudent(updatedRow);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure('فشل في تحديث الطالب: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteStudent(int id) async {
    try {
      final result = await localDataSource.deleteStudent(id);
      return Right(result > 0);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حذف الطالب: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> deleteAllStudents() async {
    try {
      final result = await localDataSource.deleteAllStudents();
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حذف الطلاب: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getStudentsCount() async {
    try {
      final result = await localDataSource.getStudentsCount();
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب عدد الطلاب: $e'));
    }
  }

  /// تحويل Model إلى Drift Companion
  StudentsCompanion _toCompanion(StudentModel model) {
    return StudentsCompanion.insert(
      studentCode: model.studentCode,
      firstName: model.firstName,
      lastName: model.lastName,
      dateOfBirth: Value(model.dateOfBirth),
      gender: Value(model.gender),
      address: Value(model.address),
      phone: Value(model.phone),
      photoPath: Value(model.photoPath),
      status: Value(model.status),
      notes: Value(model.notes),
    );
  }
}
