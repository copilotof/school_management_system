import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/groups/domain/repositories/group_repository.dart';

class DeleteGroup {
  final GroupRepository repository;
  const DeleteGroup({required this.repository});

  Future<Either<Failure, bool>> call(int id) async {
    return await repository.deleteGroup(id);
  }
}
