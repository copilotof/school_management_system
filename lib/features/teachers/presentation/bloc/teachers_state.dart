import 'package:equatable/equatable.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/teachers/domain/entities/teacher_entity.dart';

class TeachersState extends Equatable {
  final UiState<List<TeacherEntity>> teachersState;
  final String? errorMessage;

  const TeachersState({
    this.teachersState = const Initial(),
    this.errorMessage,
  });

  TeachersState copyWith({
    UiState<List<TeacherEntity>>? teachersState,
    String? errorMessage,
  }) {
    return TeachersState(
      teachersState: teachersState ?? this.teachersState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [teachersState, errorMessage];
}
