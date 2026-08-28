import 'package:equatable/equatable.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';

class SubjectsState extends Equatable {
  final UiState<List<SubjectEntity>> subjectsState;
  final String? errorMessage;

  const SubjectsState({
    this.subjectsState = const Initial(),
    this.errorMessage,
  });

  SubjectsState copyWith({
    UiState<List<SubjectEntity>>? subjectsState,
    String? errorMessage,
  }) {
    return SubjectsState(
      subjectsState: subjectsState ?? this.subjectsState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [subjectsState, errorMessage];
}
