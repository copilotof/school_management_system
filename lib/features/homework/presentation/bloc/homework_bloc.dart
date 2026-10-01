import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_entity.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_submission_entity.dart';
import 'package:school_management_system/features/homework/domain/usecases/homework_usecases.dart';

// Events
abstract class HomeworkEvent {}

class FetchAllHomeworks extends HomeworkEvent {}

class FetchHomeworksByGroup extends HomeworkEvent {
  final int groupId;
  FetchHomeworksByGroup(this.groupId);
}

class FetchHomeworksBySession extends HomeworkEvent {
  final int sessionId;
  FetchHomeworksBySession(this.sessionId);
}

class FetchSubmissions extends HomeworkEvent {
  final int homeworkId;
  FetchSubmissions(this.homeworkId);
}

class CreateHomeworkEvent extends HomeworkEvent {
  final HomeworkEntity homework;
  CreateHomeworkEvent(this.homework);
}

class UpdateHomeworkEvent extends HomeworkEvent {
  final HomeworkEntity homework;
  UpdateHomeworkEvent(this.homework);
}

class DeleteHomeworkEvent extends HomeworkEvent {
  final int id;
  DeleteHomeworkEvent(this.id);
}

class UpdateSubmissionEvent extends HomeworkEvent {
  final HomeworkSubmissionEntity submission;
  UpdateSubmissionEvent(this.submission);
}

// State
class HomeworkState {
  final UiState<List<HomeworkEntity>> homeworksState;
  final UiState<List<HomeworkSubmissionEntity>> submissionsState;
  final String? errorMessage;

  const HomeworkState({
    this.homeworksState = const Initial(),
    this.submissionsState = const Initial(),
    this.errorMessage,
  });

  HomeworkState copyWith({
    UiState<List<HomeworkEntity>>? homeworksState,
    UiState<List<HomeworkSubmissionEntity>>? submissionsState,
    String? errorMessage,
  }) {
    return HomeworkState(
      homeworksState: homeworksState ?? this.homeworksState,
      submissionsState: submissionsState ?? this.submissionsState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// BLoC
class HomeworkBloc extends Bloc<HomeworkEvent, HomeworkState> {
  final GetAllHomeworks getAllHomeworks;
  final GetHomeworksByGroup getHomeworksByGroup;
  final GetHomeworksBySession getHomeworksBySession;
  final GetHomeworksByGroupAndDateRange getHomeworksByGroupAndDateRange; // ✅

  final CreateHomework createHomework;
  final UpdateHomework updateHomework;
  final DeleteHomework deleteHomework;
  final GetSubmissionsByHomework getSubmissionsByHomework;
  final UpdateSubmission updateSubmission;

  HomeworkBloc({
    required this.getAllHomeworks,
    required this.getHomeworksByGroup,
    required this.getHomeworksBySession,
    required this.getHomeworksByGroupAndDateRange,
    required this.createHomework,
    required this.updateHomework,
    required this.deleteHomework,
    required this.getSubmissionsByHomework,
    required this.updateSubmission,
  }) : super(const HomeworkState()) {
    on<FetchAllHomeworks>(_onFetchAll);
    on<FetchHomeworksByGroup>(_onFetchByGroup);
    on<FetchHomeworksBySession>(_onFetchBySession);
    on<FetchSubmissions>(_onFetchSubmissions);
    on<CreateHomeworkEvent>(_onCreate);
    on<UpdateHomeworkEvent>(_onUpdate);
    on<DeleteHomeworkEvent>(_onDelete);
    on<UpdateSubmissionEvent>(_onUpdateSubmission);
    on<FetchHomeworksReport>(_onFetchReport);
  }

  Future<void> _onFetchReport(
    FetchHomeworksReport event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(state.copyWith(homeworksState: const Loading()));
    final result = await getHomeworksByGroupAndDateRange(
      groupId: event.groupId,
      from: event.from,
      to: event.to,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          homeworksState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (homeworks) => emit(
        state.copyWith(
          homeworksState: homeworks.isEmpty
              ? const Empty()
              : Success(homeworks),
        ),
      ),
    );
  }

  Future<void> _onFetchAll(
    FetchAllHomeworks event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(state.copyWith(homeworksState: const Loading()));
    final result = await getAllHomeworks();
    result.fold(
      (failure) => emit(
        state.copyWith(
          homeworksState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (homeworks) => emit(
        state.copyWith(
          homeworksState: homeworks.isEmpty
              ? const Empty()
              : Success(homeworks),
        ),
      ),
    );
  }

  Future<void> _onFetchByGroup(
    FetchHomeworksByGroup event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(state.copyWith(homeworksState: const Loading()));
    final result = await getHomeworksByGroup(event.groupId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          homeworksState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (homeworks) => emit(
        state.copyWith(
          homeworksState: homeworks.isEmpty
              ? const Empty()
              : Success(homeworks),
        ),
      ),
    );
  }

  Future<void> _onFetchBySession(
    FetchHomeworksBySession event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(state.copyWith(homeworksState: const Loading()));
    final result = await getHomeworksBySession(event.sessionId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          homeworksState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (homeworks) => emit(
        state.copyWith(
          homeworksState: homeworks.isEmpty
              ? const Empty()
              : Success(homeworks),
        ),
      ),
    );
  }

  Future<void> _onFetchSubmissions(
    FetchSubmissions event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(state.copyWith(submissionsState: const Loading()));
    final result = await getSubmissionsByHomework(event.homeworkId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          submissionsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (submissions) => emit(
        state.copyWith(
          submissionsState: submissions.isEmpty
              ? const Empty()
              : Success(submissions),
        ),
      ),
    );
  }

  Future<void> _onCreate(
    CreateHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    final result = await createHomework(event.homework);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchAllHomeworks()),
    );
  }

  Future<void> _onUpdate(
    UpdateHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    final result = await updateHomework(event.homework);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchAllHomeworks()),
    );
  }

  Future<void> _onDelete(
    DeleteHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    final result = await deleteHomework(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchAllHomeworks()),
    );
  }

  Future<void> _onUpdateSubmission(
    UpdateSubmissionEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    final result = await updateSubmission(event.submission);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchSubmissions(event.submission.homeworkId)),
    );
  }
}

class FetchHomeworksReport extends HomeworkEvent {
  final int groupId;
  final DateTime from;
  final DateTime to;
  FetchHomeworksReport({
    required this.groupId,
    required this.from,
    required this.to,
  });
}
