import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/enrollment/domain/entities/enrollment_entity.dart';

/// 📁 واجهة مستودع التسجيل

abstract class EnrollmentRepository {
  Future<Either<Failure, List<EnrollmentEntity>>> getAllEnrollments();
  Future<Either<Failure, List<EnrollmentEntity>>> getEnrollmentsByStudent(
    int studentId,
  );
  Future<Either<Failure, List<EnrollmentEntity>>> getEnrollmentsByGroup(
    int groupId,
  );
  Future<Either<Failure, int>> createEnrollment(EnrollmentEntity enrollment);
  Future<Either<Failure, bool>> updateEnrollment(EnrollmentEntity enrollment);
  Future<Either<Failure, bool>> deleteEnrollment(int id);
  Future<Either<Failure, int>> getEnrollmentsCount();
  Future<Either<Failure, int>> getStudentsCountByGroup(int groupId);
}
