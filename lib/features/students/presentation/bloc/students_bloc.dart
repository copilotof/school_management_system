import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/domain/usecases/create_student.dart';
import 'package:school_management_system/features/students/domain/usecases/delete_student.dart';
import 'package:school_management_system/features/students/domain/usecases/get_all_students.dart';
import 'package:school_management_system/features/students/domain/usecases/search_students.dart';
import 'package:school_management_system/features/students/domain/usecases/update_student.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_state.dart';

/// 📁 إدارة حالة الطلاب (BLoC)
/// يتبع مبدأ Single Responsibility

class StudentsBloc extends Bloc<StudentsEvent, StudentsState> {
  final GetAllStudents _getAllStudents;
  final SearchStudents _searchStudents;
  final CreateStudent _createStudent;
  final UpdateStudent _updateStudent;
  final DeleteStudent _deleteStudent;

  // إدارة الاشتراكات (لتفادي تسريبات الذاكرة)
  StreamSubscription? _studentsSubscription;

  StudentsBloc({
    required GetAllStudents getAllStudents,
    required SearchStudents searchStudents,
    required CreateStudent createStudent,
    required UpdateStudent updateStudent,
    required DeleteStudent deleteStudent,
  }) : _getAllStudents = getAllStudents,
       _searchStudents = searchStudents,
       _createStudent = createStudent,
       _updateStudent = updateStudent,
       _deleteStudent = deleteStudent,
       super(const StudentsState()) {
    on<FetchStudents>(_onFetchStudents);
    on<SearchStudentsEvent>(_onSearchStudents);
    on<CreateStudentEvent>(_onCreateStudent);
    on<UpdateStudentEvent>(_onUpdateStudent);
    on<DeleteStudentEvent>(_onDeleteStudent);
  }

  /// جلب كل الطلاب
  Future<void> _onFetchStudents(
    FetchStudents event,
    Emitter<StudentsState> emit,
  ) async {
    emit(
      state.copyWith(
        studentsState: const Loading(),
        isSearching: false,
        errorMessage: null,
      ),
    );

    final result = await _getAllStudents();

    result.fold(
      (failure) => emit(
        state.copyWith(
          studentsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (students) => emit(
        state.copyWith(
          studentsState: students.isEmpty ? const Empty() : Success(students),
          searchQuery: '',
          isSearching: false,
        ),
      ),
    );
  }

  /// البحث
  Future<void> _onSearchStudents(
    SearchStudentsEvent event,
    Emitter<StudentsState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const FetchStudents());
      return;
    }

    emit(state.copyWith(isSearching: true));

    final result = await _searchStudents(event.query);

    result.fold(
      (failure) => emit(
        state.copyWith(
          studentsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (students) => emit(
        state.copyWith(
          studentsState: students.isEmpty ? const Empty() : Success(students),
          searchQuery: event.query,
          isSearching: true,
        ),
      ),
    );
  }

  /// إنشاء
  Future<void> _onCreateStudent(
    CreateStudentEvent event,
    Emitter<StudentsState> emit,
  ) async {
    final result = await _createStudent(event.student);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(const FetchStudents()),
    );
  }

  /// تحديث
  Future<void> _onUpdateStudent(
    UpdateStudentEvent event,
    Emitter<StudentsState> emit,
  ) async {
    final result = await _updateStudent(event.student);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(const FetchStudents()),
    );
  }

  /// حذف
  Future<void> _onDeleteStudent(
    DeleteStudentEvent event,
    Emitter<StudentsState> emit,
  ) async {
    final result = await _deleteStudent(event.id);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(const FetchStudents()),
    );
  }

  /// إغلاق الاشتراكات (مهم جداً لتفادي تسريبات الذاكرة)
  @override
  Future<void> close() {
    _studentsSubscription?.cancel();
    return super.close();
  }
}
