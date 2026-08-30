import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/enrollment/domain/entities/enrollment_entity.dart';
import 'package:school_management_system/features/enrollment/domain/repositories/enrollment_repository.dart';

class CreateEnrollment {
  final EnrollmentRepository repository;
  const CreateEnrollment({required this.repository});

  Future<Either<Failure, int>> call(EnrollmentEntity enrollment) async {
    return await repository.createEnrollment(enrollment);
  }
}
