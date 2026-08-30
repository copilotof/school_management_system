import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/enrollment/data/models/enrollment_mapper.dart';
import 'package:school_management_system/features/enrollment/data/sources/enrollment_local_source.dart';
import 'package:school_management_system/features/enrollment/domain/entities/enrollment_entity.dart';
import 'package:school_management_system/features/enrollment/domain/repositories/enrollment_repository.dart';

class EnrollmentRepositoryImpl implements EnrollmentRepository {
  final EnrollmentLocalDataSource localDataSource;

  EnrollmentRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<EnrollmentEntity>>> getAllEnrollments() async {
    try {
      debugPrint('🟡 Repository.getAllEnrollments: جاري الاستعلام...');
      final rows = await localDataSource.getAllEnrollments();
      debugPrint('🟢 Repository.getAllEnrollments: تم جلب ${rows.length} صف');
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e, stackTrace) {
      debugPrint('🔴 Repository.getAllEnrollments خطأ: $e');
      debugPrint('Stack: $stackTrace');
      return Left(DatabaseFailure('فشل في جلب التسجيلات: $e'));
    }
  }

  @override
  Future<Either<Failure, List<EnrollmentEntity>>> getEnrollmentsByStudent(
    int studentId,
  ) async {
    try {
      final rows = await localDataSource.getEnrollmentsByStudent(studentId);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب تسجيلات الطالب: $e'));
    }
  }

  @override
  Future<Either<Failure, List<EnrollmentEntity>>> getEnrollmentsByGroup(
    int groupId,
  ) async {
    try {
      final rows = await localDataSource.getEnrollmentsByGroup(groupId);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب تسجيلات الفوج: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createEnrollment(
    EnrollmentEntity enrollment,
  ) async {
    try {
      debugPrint(
        '🟡 Repository.createEnrollment: studentId=${enrollment.studentId}, groupId=${enrollment.groupId}',
      );
      final companion = EnrollmentMapper.fromEntity(enrollment);
      final id = await localDataSource.createEnrollment(companion);
      debugPrint('🟢 Repository.createEnrollment: تم الحفظ id=$id');
      return Right(id);
    } catch (e, stackTrace) {
      debugPrint('🔴 Repository.createEnrollment خطأ: $e');
      debugPrint('Stack: $stackTrace');
      return Left(DatabaseFailure('فشل في إنشاء التسجيل: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateEnrollment(
    EnrollmentEntity enrollment,
  ) async {
    try {
      final row = await localDataSource.getEnrollmentById(enrollment.id!);
      if (row == null) return const Left(NotFoundFailure('التسجيل غير موجود'));
      final updated = row.copyWith(
        studentId: enrollment.studentId,
        groupId: enrollment.groupId,
        enrollmentDate: enrollment.enrollmentDate,
        registrationFee: enrollment.registrationFee,
        status: enrollment.status,
        notes: Value(enrollment.notes),
      );
      return Right(await localDataSource.updateEnrollment(updated));
    } catch (e) {
      return Left(DatabaseFailure('فشل في تحديث التسجيل: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteEnrollment(int id) async {
    try {
      debugPrint('🟡 Repository.deleteEnrollment: id=$id');
      final result = await localDataSource.deleteEnrollment(id);
      debugPrint('🟢 Repository.deleteEnrollment: تم الحذف result=$result');
      return Right(result > 0);
    } catch (e) {
      debugPrint('🔴 Repository.deleteEnrollment خطأ: $e');
      return Left(DatabaseFailure('فشل في حذف التسجيل: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getEnrollmentsCount() async {
    try {
      return Right(await localDataSource.getEnrollmentsCount());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب عدد التسجيلات: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getStudentsCountByGroup(int groupId) async {
    try {
      return Right(await localDataSource.getStudentsCountByGroup(groupId));
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب عدد الطلاب: $e'));
    }
  }
}
