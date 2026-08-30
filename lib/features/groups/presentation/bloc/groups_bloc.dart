import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/groups/domain/usecases/create_group.dart';
import 'package:school_management_system/features/groups/domain/usecases/delete_group.dart';
import 'package:school_management_system/features/groups/domain/usecases/get_all_groups.dart';
import 'package:school_management_system/features/groups/domain/usecases/search_groups.dart';
import 'package:school_management_system/features/groups/domain/usecases/update_group.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_event.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_state.dart';

class GroupsBloc extends Bloc<GroupsEvent, GroupsState> {
  final GetAllGroups _getAllGroups;
  final SearchGroups _searchGroups;
  final CreateGroup _createGroup;
  final UpdateGroup _updateGroup;
  final DeleteGroup _deleteGroup;

  GroupsBloc({
    required GetAllGroups getAllGroups,
    required SearchGroups searchGroups,
    required CreateGroup createGroup,
    required UpdateGroup updateGroup,
    required DeleteGroup deleteGroup,
  }) : _getAllGroups = getAllGroups,
       _searchGroups = searchGroups,
       _createGroup = createGroup,
       _updateGroup = updateGroup,
       _deleteGroup = deleteGroup,
       super(const GroupsState()) {
    on<FetchGroups>(_onFetchGroups);
    on<SearchGroupsEvent>(_onSearchGroups);
    on<CreateGroupEvent>(_onCreateGroup);
    on<UpdateGroupEvent>(_onUpdateGroup);
    on<DeleteGroupEvent>(_onDeleteGroup);
  }

  Future<void> _onFetchGroups(
    FetchGroups event,
    Emitter<GroupsState> emit,
  ) async {
    emit(state.copyWith(groupsState: const Loading()));

    final result = await _getAllGroups();

    result.fold(
      (failure) => emit(
        state.copyWith(
          groupsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (groups) => emit(
        state.copyWith(
          groupsState: groups.isEmpty ? const Empty() : Success(groups),
        ),
      ),
    );
  }

  Future<void> _onSearchGroups(
    SearchGroupsEvent event,
    Emitter<GroupsState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const FetchGroups());
      return;
    }

    final result = await _searchGroups(event.query);

    result.fold(
      (failure) => emit(
        state.copyWith(
          groupsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (groups) => emit(
        state.copyWith(
          groupsState: groups.isEmpty ? const Empty() : Success(groups),
        ),
      ),
    );
  }

  Future<void> _onCreateGroup(
    CreateGroupEvent event,
    Emitter<GroupsState> emit,
  ) async {
    final result = await _createGroup(event.group);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(const FetchGroups()),
    );
  }

  Future<void> _onUpdateGroup(
    UpdateGroupEvent event,
    Emitter<GroupsState> emit,
  ) async {
    final result = await _updateGroup(event.group);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(const FetchGroups()),
    );
  }

  Future<void> _onDeleteGroup(
    DeleteGroupEvent event,
    Emitter<GroupsState> emit,
  ) async {
    final result = await _deleteGroup(event.id);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(const FetchGroups()),
    );
  }
}
