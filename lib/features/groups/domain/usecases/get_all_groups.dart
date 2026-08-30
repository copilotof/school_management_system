import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/groups/domain/repositories/group_repository.dart';

class GetAllGroups {
  final GroupRepository repository;
  const GetAllGroups({required this.repository});

  Future<Either<Failure, List<GroupEntity>>> call() async {
    return await repository.getAllGroups();
  }
}
