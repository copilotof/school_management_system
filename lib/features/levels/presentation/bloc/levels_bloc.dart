import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/levels/domain/entities/level_entity.dart';
import 'package:school_management_system/features/levels/domain/repositories/level_repository.dart';

// Events
abstract class LevelsEvent {}

class FetchLevels extends LevelsEvent {}

class CreateLevelEvent extends LevelsEvent {
  final LevelEntity level;
  CreateLevelEvent(this.level);
}

class UpdateLevelEvent extends LevelsEvent {
  final LevelEntity level;
  UpdateLevelEvent(this.level);
}

class DeleteLevelEvent extends LevelsEvent {
  final int id;
  DeleteLevelEvent(this.id);
}

// State
class LevelsState {
  final UiState<List<LevelEntity>> levelsState;
  final String? errorMessage;

  const LevelsState({this.levelsState = const Initial(), this.errorMessage});

  LevelsState copyWith({
    UiState<List<LevelEntity>>? levelsState,
    String? errorMessage,
  }) {
    return LevelsState(
      levelsState: levelsState ?? this.levelsState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// BLoC
class LevelsBloc extends Bloc<LevelsEvent, LevelsState> {
  final LevelRepository repository;

  LevelsBloc({required this.repository}) : super(const LevelsState()) {
    on<FetchLevels>(_onFetchLevels);
    on<CreateLevelEvent>(_onCreateLevel);
    on<UpdateLevelEvent>(_onUpdateLevel);
    on<DeleteLevelEvent>(_onDeleteLevel);
  }

  Future<void> _onFetchLevels(
    FetchLevels event,
    Emitter<LevelsState> emit,
  ) async {
    emit(state.copyWith(levelsState: const Loading()));
    final result = await repository.getAllLevels();
    result.fold(
      (failure) => emit(
        state.copyWith(
          levelsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (levels) => emit(
        state.copyWith(
          levelsState: levels.isEmpty ? const Empty() : Success(levels),
        ),
      ),
    );
  }

  Future<void> _onCreateLevel(
    CreateLevelEvent event,
    Emitter<LevelsState> emit,
  ) async {
    final result = await repository.createLevel(event.level);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchLevels()),
    );
  }

  Future<void> _onUpdateLevel(
    UpdateLevelEvent event,
    Emitter<LevelsState> emit,
  ) async {
    final result = await repository.updateLevel(event.level);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchLevels()),
    );
  }

  Future<void> _onDeleteLevel(
    DeleteLevelEvent event,
    Emitter<LevelsState> emit,
  ) async {
    final result = await repository.deleteLevel(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchLevels()),
    );
  }
}
