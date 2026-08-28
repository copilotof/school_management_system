import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/subjects/domain/usecases/create_subject.dart';
import 'package:school_management_system/features/subjects/domain/usecases/delete_subject.dart';
import 'package:school_management_system/features/subjects/domain/usecases/get_all_subjects.dart';
import 'package:school_management_system/features/subjects/domain/usecases/search_subjects.dart';
import 'package:school_management_system/features/subjects/domain/usecases/update_subject.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_event.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_state.dart';

class SubjectsBloc extends Bloc<SubjectsEvent, SubjectsState> {
  final GetAllSubjects _getAllSubjects;
  final SearchSubjects _searchSubjects;
  final CreateSubject _createSubject;
  final UpdateSubject _updateSubject;
  final DeleteSubject _deleteSubject;

  SubjectsBloc({
    required GetAllSubjects getAllSubjects,
    required SearchSubjects searchSubjects,
    required CreateSubject createSubject,
    required UpdateSubject updateSubject,
    required DeleteSubject deleteSubject,
  }) : _getAllSubjects = getAllSubjects,
       _searchSubjects = searchSubjects,
       _createSubject = createSubject,
       _updateSubject = updateSubject,
       _deleteSubject = deleteSubject,
       super(const SubjectsState()) {
    on<FetchSubjects>(_onFetchSubjects);
    on<SearchSubjectsEvent>(_onSearchSubjects);
    on<CreateSubjectEvent>(_onCreateSubject);
    on<UpdateSubjectEvent>(_onUpdateSubject);
    on<DeleteSubjectEvent>(_onDeleteSubject);
  }

  Future<void> _onFetchSubjects(
    FetchSubjects event,
    Emitter<SubjectsState> emit,
  ) async {
    emit(state.copyWith(subjectsState: const Loading()));

    final result = await _getAllSubjects();

    result.fold(
      (failure) => emit(
        state.copyWith(
          subjectsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (subjects) => emit(
        state.copyWith(
          subjectsState: subjects.isEmpty ? const Empty() : Success(subjects),
        ),
      ),
    );
  }

  Future<void> _onSearchSubjects(
    SearchSubjectsEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const FetchSubjects());
      return;
    }

    final result = await _searchSubjects(event.query);

    result.fold(
      (failure) => emit(
        state.copyWith(
          subjectsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (subjects) => emit(
        state.copyWith(
          subjectsState: subjects.isEmpty ? const Empty() : Success(subjects),
        ),
      ),
    );
  }

  Future<void> _onCreateSubject(
    CreateSubjectEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    final result = await _createSubject(event.subject);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(const FetchSubjects()),
    );
  }

  Future<void> _onUpdateSubject(
    UpdateSubjectEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    final result = await _updateSubject(event.subject);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(const FetchSubjects()),
    );
  }

  Future<void> _onDeleteSubject(
    DeleteSubjectEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    final result = await _deleteSubject(event.id);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(const FetchSubjects()),
    );
  }
}
