import 'package:equatable/equatable.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';

abstract class GroupsEvent extends Equatable {
  const GroupsEvent();

  @override
  List<Object?> get props => [];
}

class FetchGroups extends GroupsEvent {
  const FetchGroups();
}

class SearchGroupsEvent extends GroupsEvent {
  final String query;
  const SearchGroupsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class CreateGroupEvent extends GroupsEvent {
  final GroupEntity group;
  const CreateGroupEvent(this.group);

  @override
  List<Object?> get props => [group];
}

class UpdateGroupEvent extends GroupsEvent {
  final GroupEntity group;
  const UpdateGroupEvent(this.group);

  @override
  List<Object?> get props => [group];
}

class DeleteGroupEvent extends GroupsEvent {
  final int id;
  const DeleteGroupEvent(this.id);

  @override
  List<Object?> get props => [id];
}
