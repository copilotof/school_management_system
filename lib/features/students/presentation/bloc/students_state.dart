import 'package:equatable/equatable.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

/// 📁 حالات الطلاب
/// تستخدم UiState الموحد

class StudentsState extends Equatable {
  final UiState<List<StudentEntity>> studentsState;
  final String searchQuery;
  final bool isSearching;
  final String? errorMessage;

  const StudentsState({
    this.studentsState = const Initial(),
    this.searchQuery = '',
    this.isSearching = false,
    this.errorMessage,
  });

  StudentsState copyWith({
    UiState<List<StudentEntity>>? studentsState,
    String? searchQuery,
    bool? isSearching,
    String? errorMessage,
  }) {
    return StudentsState(
      studentsState: studentsState ?? this.studentsState,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    studentsState,
    searchQuery,
    isSearching,
    errorMessage,
  ];
}
