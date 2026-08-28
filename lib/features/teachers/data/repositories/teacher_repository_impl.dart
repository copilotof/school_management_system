import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/teachers/data/models/teacher_mapper.dart';
import 'package:school_management_system/features/teachers/data/sources/teacher_local_source.dart';
import 'package:school_management_system/features/teachers/domain/entities/teacher_entity.dart';
import 'package:school_management_system/features/teachers/domain/repositories/teacher_repository.dart';

/// 📁 تنفيذ مستودع المعلمين

class TeacherRepositoryImpl implements TeacherRepository {
  final TeacherLocalDataSource localDataSource;

  TeacherRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<TeacherEntity>>> getAllTeachers() async {
    try {
      final rows = await localDataSource.getAllTeachers();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب المعلمين: $e'));
    }
  }

  @override
  Future<Either<Failure, TeacherEntity?>> getTeacherById(int id) async {
    try {
      final row = await localDataSource.getTeacherById(id);
      return Right(row?.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب المعلم: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TeacherEntity>>> searchTeachers(String query) async {
    try {
      final rows = await localDataSource.searchTeachers(query);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في البحث: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createTeacher(TeacherEntity teacher) async {
    try {
      final companion = TeacherMapper.fromEntity(teacher);
      final id = await localDataSource.createTeacher(companion);
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure('فشل في إنشاء المعلم: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateTeacher(TeacherEntity teacher) async {
    try {
      final current = await localDataSource.getTeacherById(teacher.id!);
      if (current == null) {
        return const Left(NotFoundFailure('المعلم غير موجود'));
      }
      final updated = current.copyWith(
        fullName: teacher.fullName,
        phone: Value(teacher.phone),
        email: Value(teacher.email),
        specialization: Value(teacher.specialization),
        hireDate: Value(teacher.hireDate),
        isActive: teacher.isActive,
      );
      final result = await localDataSource.updateTeacher(updated);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure('فشل في تحديث المعلم: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteTeacher(int id) async {
    try {
      final result = await localDataSource.deleteTeacher(id);
      return Right(result > 0);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حذف المعلم: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getTeachersCount() async {
    try {
      return Right(await localDataSource.getTeachersCount());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب عدد المعلمين: $e'));
    }
  }
}