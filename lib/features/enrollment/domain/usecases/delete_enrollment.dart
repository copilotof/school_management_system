import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/enrollment/domain/repositories/enrollment_repository.dart';

class DeleteEnrollment {
  final EnrollmentRepository repository;
  const DeleteEnrollment({required this.repository});

  Future<Either<Failure, bool>> call(int id) async {
    return await repository.deleteEnrollment(id);
  }
}
