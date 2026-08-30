import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/enrollment/domain/entities/enrollment_entity.dart';
import 'package:school_management_system/features/enrollment/domain/repositories/enrollment_repository.dart';

class GetAllEnrollments {
  final EnrollmentRepository repository;
  const GetAllEnrollments({required this.repository});

  Future<Either<Failure, List<EnrollmentEntity>>> call() async {
    return await repository.getAllEnrollments();
  }
}
