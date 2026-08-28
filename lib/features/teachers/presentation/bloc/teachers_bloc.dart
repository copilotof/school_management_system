import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/teachers/domain/usecases/create_teacher.dart';
import 'package:school_management_system/features/teachers/domain/usecases/delete_teacher.dart';
import 'package:school_management_system/features/teachers/domain/usecases/get_all_teachers.dart';
import 'package:school_management_system/features/teachers/domain/usecases/search_teachers.dart';
import 'package:school_management_system/features/teachers/domain/usecases/update_teacher.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_event.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_state.dart';

class TeachersBloc extends Bloc<TeachersEvent, TeachersState> {
  final GetAllTeachers _getAllTeachers;
  final SearchTeachers _searchTeachers;
  final CreateTeacher _createTeacher;
  final UpdateTeacher _updateTeacher;
  final DeleteTeacher _deleteTeacher;

  TeachersBloc({
    required GetAllTeachers getAllTeachers,
    required SearchTeachers searchTeachers,
    required CreateTeacher createTeacher,
    required UpdateTeacher updateTeacher,
    required DeleteTeacher deleteTeacher,
  }) : _getAllTeachers = getAllTeachers,
       _searchTeachers = searchTeachers,
       _createTeacher = createTeacher,
       _updateTeacher = updateTeacher,
       _deleteTeacher = deleteTeacher,
       super(const TeachersState()) {
    on<FetchTeachers>(_onFetchTeachers);
    on<SearchTeachersEvent>(_onSearchTeachers);
    on<CreateTeacherEvent>(_onCreateTeacher);
    on<UpdateTeacherEvent>(_onUpdateTeacher);
    on<DeleteTeacherEvent>(_onDeleteTeacher);
  }

  Future<void> _onFetchTeachers(
    FetchTeachers event,
    Emitter<TeachersState> emit,
  ) async {
    emit(state.copyWith(teachersState: const Loading()));

    final result = await _getAllTeachers();

    result.fold(
      (failure) => emit(
        state.copyWith(
          teachersState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (teachers) => emit(
        state.copyWith(
          teachersState: teachers.isEmpty ? const Empty() : Success(teachers),
        ),
      ),
    );
  }

  Future<void> _onSearchTeachers(
    SearchTeachersEvent event,
    Emitter<TeachersState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const FetchTeachers());
      return;
    }

    final result = await _searchTeachers(event.query);

    result.fold(
      (failure) => emit(
        state.copyWith(
          teachersState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (teachers) => emit(
        state.copyWith(
          teachersState: teachers.isEmpty ? const Empty() : Success(teachers),
        ),
      ),
    );
  }

  Future<void> _onCreateTeacher(
    CreateTeacherEvent event,
    Emitter<TeachersState> emit,
  ) async {
    final result = await _createTeacher(event.teacher);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(const FetchTeachers()),
    );
  }

  Future<void> _onUpdateTeacher(
    UpdateTeacherEvent event,
    Emitter<TeachersState> emit,
  ) async {
    final result = await _updateTeacher(event.teacher);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(const FetchTeachers()),
    );
  }

  Future<void> _onDeleteTeacher(
    DeleteTeacherEvent event,
    Emitter<TeachersState> emit,
  ) async {
    final result = await _deleteTeacher(event.id);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(const FetchTeachers()),
    );
  }
}
