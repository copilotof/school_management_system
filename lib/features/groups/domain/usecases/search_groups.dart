import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/groups/domain/repositories/group_repository.dart';

class SearchGroups {
  final GroupRepository repository;
  const SearchGroups({required this.repository});

  Future<Either<Failure, List<GroupEntity>>> call(String query) async {
    return await repository.searchGroups(query);
  }
}
