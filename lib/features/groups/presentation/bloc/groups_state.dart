import 'package:equatable/equatable.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';

class GroupsState extends Equatable {
  final UiState<List<GroupEntity>> groupsState;
  final String? errorMessage;

  const GroupsState({this.groupsState = const Initial(), this.errorMessage});

  GroupsState copyWith({
    UiState<List<GroupEntity>>? groupsState,
    String? errorMessage,
  }) {
    return GroupsState(
      groupsState: groupsState ?? this.groupsState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [groupsState, errorMessage];
}
