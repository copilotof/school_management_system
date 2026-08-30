import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/grades/domain/entities/grade_entity.dart';
import 'package:school_management_system/features/grades/domain/repositories/grade_repository.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';

// Events
abstract class GradesEvent {}

class FetchGrades extends GradesEvent {}

class CreateGradeEvent extends GradesEvent {
  final GradeEntity grade;
  CreateGradeEvent(this.grade);
}

class UpdateGradeEvent extends GradesEvent {
  final GradeEntity grade;
  UpdateGradeEvent(this.grade);
}

class DeleteGradeEvent extends GradesEvent {
  final int id;
  DeleteGradeEvent(this.id);
}

class FetchGradeSubjects extends GradesEvent {
  final int gradeId;
  FetchGradeSubjects(this.gradeId);
}

class SaveGradeSubjects extends GradesEvent {
  final int gradeId;
  final List<int> subjectIds;
  SaveGradeSubjects({required this.gradeId, required this.subjectIds});
}

// State
class GradesState {
  final UiState<List<GradeEntity>> gradesState;
  final UiState<List<SubjectEntity>> gradeSubjectsState;
  final String? errorMessage;

  const GradesState({
    this.gradesState = const Initial(),
    this.gradeSubjectsState = const Initial(),
    this.errorMessage,
  });

  GradesState copyWith({
    UiState<List<GradeEntity>>? gradesState,
    UiState<List<SubjectEntity>>? gradeSubjectsState,
    String? errorMessage,
  }) {
    return GradesState(
      gradesState: gradesState ?? this.gradesState,
      gradeSubjectsState: gradeSubjectsState ?? this.gradeSubjectsState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// BLoC
class GradesBloc extends Bloc<GradesEvent, GradesState> {
  final GradeRepository repository;

  GradesBloc({required this.repository}) : super(const GradesState()) {
    on<FetchGrades>(_onFetchGrades);
    on<CreateGradeEvent>(_onCreateGrade);
    on<UpdateGradeEvent>(_onUpdateGrade);
    on<DeleteGradeEvent>(_onDeleteGrade);
    on<FetchGradeSubjects>(_onFetchGradeSubjects);
    on<SaveGradeSubjects>(_onSaveGradeSubjects);
  }

  Future<void> _onFetchGrades(
    FetchGrades event,
    Emitter<GradesState> emit,
  ) async {
    emit(state.copyWith(gradesState: const Loading()));
    final result = await repository.getAllGrades();
    result.fold(
      (failure) => emit(
        state.copyWith(
          gradesState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (grades) => emit(
        state.copyWith(
          gradesState: grades.isEmpty ? const Empty() : Success(grades),
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onCreateGrade(
    CreateGradeEvent event,
    Emitter<GradesState> emit,
  ) async {
    final result = await repository.createGrade(event.grade);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchGrades()),
    );
  }

  Future<void> _onUpdateGrade(
    UpdateGradeEvent event,
    Emitter<GradesState> emit,
  ) async {
    final result = await repository.updateGrade(event.grade);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchGrades()),
    );
  }

  Future<void> _onDeleteGrade(
    DeleteGradeEvent event,
    Emitter<GradesState> emit,
  ) async {
    final result = await repository.deleteGrade(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchGrades()),
    );
  }

  /// ✅ جلب المواد المرتبطة بصف - يحدّث الـ state بشكل صحيح
  Future<void> _onFetchGradeSubjects(
    FetchGradeSubjects event,
    Emitter<GradesState> emit,
  ) async {
    emit(state.copyWith(gradeSubjectsState: const Loading()));
    final result = await repository.getSubjectsByGrade(event.gradeId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          gradeSubjectsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (subjects) => emit(
        state.copyWith(
          gradeSubjectsState: subjects.isEmpty
              ? const Empty()
              : Success(subjects),
          errorMessage: null,
        ),
      ),
    );
  }

  /// ✅ حفظ المواد المرتبطة - يعيد الجلب بعد الحفظ
  Future<void> _onSaveGradeSubjects(
    SaveGradeSubjects event,
    Emitter<GradesState> emit,
  ) async {
    final result = await repository.saveSubjectsForGrade(
      gradeId: event.gradeId,
      subjectIds: event.subjectIds,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        // ✅ إعادة جلب المواد المرتبطة بعد الحفظ
        add(FetchGradeSubjects(event.gradeId));
      },
    );
  }
}
