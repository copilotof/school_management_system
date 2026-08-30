import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';

/// 📁 واجهة مستودع الأفواج

abstract class GroupRepository {
  Future<Either<Failure, List<GroupEntity>>> getAllGroups();
  Future<Either<Failure, GroupEntity?>> getGroupById(int id);
  Future<Either<Failure, List<GroupEntity>>> searchGroups(String query);
  Future<Either<Failure, int>> createGroup(GroupEntity group);
  Future<Either<Failure, bool>> updateGroup(GroupEntity group);
  Future<Either<Failure, bool>> deleteGroup(int id);
  Future<Either<Failure, int>> getGroupsCount();
}
