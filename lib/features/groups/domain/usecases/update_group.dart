import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/groups/domain/repositories/group_repository.dart';

class UpdateGroup {
  final GroupRepository repository;
  const UpdateGroup({required this.repository});

  Future<Either<Failure, bool>> call(GroupEntity group) async {
    return await repository.updateGroup(group);
  }
}
