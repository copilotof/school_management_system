import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/enrollment/domain/entities/enrollment_entity.dart';
import 'package:school_management_system/features/enrollment/domain/repositories/enrollment_repository.dart';

// Events
abstract class EnrollmentEvent {}

class FetchEnrollments extends EnrollmentEvent {}

class CreateEnrollmentEvent extends EnrollmentEvent {
  final EnrollmentEntity enrollment;
  CreateEnrollmentEvent(this.enrollment);
}

class DeleteEnrollmentEvent extends EnrollmentEvent {
  final int id;
  DeleteEnrollmentEvent(this.id);
}

// State
class EnrollmentState {
  final UiState<List<EnrollmentEntity>> enrollmentsState;
  final String? errorMessage;

  const EnrollmentState({
    this.enrollmentsState = const Initial(),
    this.errorMessage,
  });

  EnrollmentState copyWith({
    UiState<List<EnrollmentEntity>>? enrollmentsState,
    String? errorMessage,
  }) {
    return EnrollmentState(
      enrollmentsState: enrollmentsState ?? this.enrollmentsState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// BLoC
class EnrollmentBloc extends Bloc<EnrollmentEvent, EnrollmentState> {
  final EnrollmentRepository repository;

  EnrollmentBloc({required this.repository}) : super(const EnrollmentState()) {
    on<FetchEnrollments>(_onFetchEnrollments);
    on<CreateEnrollmentEvent>(_onCreateEnrollment);
    on<DeleteEnrollmentEvent>(_onDeleteEnrollment);
  }

  Future<void> _onFetchEnrollments(
    FetchEnrollments event,
    Emitter<EnrollmentState> emit,
  ) async {
    debugPrint('🔵 FetchEnrollments: جاري التحميل...');
    emit(state.copyWith(enrollmentsState: const Loading()));
    final result = await repository.getAllEnrollments();
    result.fold(
      (failure) {
        debugPrint('🔴 FetchEnrollments فشل: ${failure.message}');
        emit(
          state.copyWith(
            enrollmentsState: Error(failure.message),
            errorMessage: failure.message,
          ),
        );
      },
      (enrollments) {
        debugPrint('🟢 FetchEnrollments نجح: ${enrollments.length} تسجيل');
        for (final e in enrollments) {
          debugPrint(
            '   - studentId: ${e.studentId}, groupId: ${e.groupId}, status: ${e.status}',
          );
        }
        emit(
          state.copyWith(
            enrollmentsState: enrollments.isEmpty
                ? const Empty()
                : Success(enrollments),
          ),
        );
      },
    );
  }

  Future<void> _onCreateEnrollment(
    CreateEnrollmentEvent event,
    Emitter<EnrollmentState> emit,
  ) async {
    debugPrint(
      '🔵 CreateEnrollment: studentId=${event.enrollment.studentId}, groupId=${event.enrollment.groupId}',
    );
    final result = await repository.createEnrollment(event.enrollment);
    result.fold(
      (failure) {
        debugPrint('🔴 CreateEnrollment فشل: ${failure.message}');
        emit(state.copyWith(errorMessage: failure.message));
      },
      (id) {
        debugPrint('🟢 CreateEnrollment نجح: id=$id');
        add(FetchEnrollments());
      },
    );
  }

  Future<void> _onDeleteEnrollment(
    DeleteEnrollmentEvent event,
    Emitter<EnrollmentState> emit,
  ) async {
    debugPrint('🔵 DeleteEnrollment: id=${event.id}');
    final result = await repository.deleteEnrollment(event.id);
    result.fold(
      (failure) {
        debugPrint('🔴 DeleteEnrollment فشل: ${failure.message}');
        emit(state.copyWith(errorMessage: failure.message));
      },
      (_) {
        debugPrint('🟢 DeleteEnrollment نجح');
        add(FetchEnrollments());
      },
    );
  }
}
