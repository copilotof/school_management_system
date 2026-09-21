import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/attendance/domain/entities/attendance_entity.dart';
import 'package:school_management_system/features/attendance/domain/entities/session_entity.dart';
import 'package:school_management_system/features/attendance/domain/repositories/attendance_repository.dart';

import '../../domain/entities/schedule_template_entity.dart';

// ============================================================
// ✅ Events - كلها معرفة في المستوى الأعلى
// ============================================================

abstract class AttendanceEvent {}

class FetchTodaySessions extends AttendanceEvent {}

class GenerateTodaySessions extends AttendanceEvent {}

class FetchSessionsByGroup extends AttendanceEvent {
  final int groupId;
  FetchSessionsByGroup(this.groupId);
}

class FetchSessionsByDate extends AttendanceEvent {
  final DateTime date;
  FetchSessionsByDate(this.date);
}

class FetchAttendanceBySession extends AttendanceEvent {
  final int sessionId;
  FetchAttendanceBySession(this.sessionId);
}

class CreateSessionEvent extends AttendanceEvent {
  final SessionEntity session;
  CreateSessionEvent(this.session);
}

class UpdateSessionEvent extends AttendanceEvent {
  final SessionEntity session;
  UpdateSessionEvent(this.session);
}

class DeleteSessionEvent extends AttendanceEvent {
  final int id;
  DeleteSessionEvent(this.id);
}

class SaveAttendanceEvent extends AttendanceEvent {
  final int sessionId;
  final List<AttendanceEntity> attendanceList;
  SaveAttendanceEvent({required this.sessionId, required this.attendanceList});
}

/// ✅ توليد الحصص لتاريخ معين
class GenerateSessionsForDate extends AttendanceEvent {
  final DateTime date;
  GenerateSessionsForDate(this.date);
}

class FetchTemplatesByGroup extends AttendanceEvent {
  final int groupId;
  FetchTemplatesByGroup(this.groupId);
}

class CreateTemplateEvent extends AttendanceEvent {
  final ScheduleTemplateEntity template;
  CreateTemplateEvent(this.template);
}

class UpdateTemplateEvent extends AttendanceEvent {
  final ScheduleTemplateEntity template;
  UpdateTemplateEvent(this.template);
}

class DeleteTemplateEvent extends AttendanceEvent {
  final int id;
  final int groupId;
  DeleteTemplateEvent({required this.id, required this.groupId});
}

class UnexemptStudentFromExtraFee extends AttendanceEvent {
  final int sessionId;
  final int studentId;
  UnexemptStudentFromExtraFee({
    required this.sessionId,
    required this.studentId,
  });
}

// ============================================================
// ✅ State
// ============================================================

class AttendanceState {
  final UiState<List<SessionEntity>> sessionsState;
  final UiState<List<AttendanceEntity>> attendanceState;
  final UiState<List<ScheduleTemplateEntity>> templatesState; // ✅ جديد
  final String? errorMessage;

  const AttendanceState({
    this.sessionsState = const Initial(),
    this.attendanceState = const Initial(),
    this.templatesState = const Initial(), // ✅
    this.errorMessage,
  });

  AttendanceState copyWith({
    UiState<List<SessionEntity>>? sessionsState,
    UiState<List<AttendanceEntity>>? attendanceState,
    UiState<List<ScheduleTemplateEntity>>? templatesState,
    String? errorMessage,
  }) {
    return AttendanceState(
      sessionsState: sessionsState ?? this.sessionsState,
      attendanceState: attendanceState ?? this.attendanceState,
      templatesState: templatesState ?? this.templatesState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ExemptStudentFromExtraFee extends AttendanceEvent {
  final int sessionId;
  final int studentId;
  ExemptStudentFromExtraFee({required this.sessionId, required this.studentId});
}

// ============================================================
// ✅ BLoC
// ============================================================

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository repository;

  AttendanceBloc({required this.repository}) : super(const AttendanceState()) {
    on<FetchTodaySessions>(_onFetchTodaySessions);
    on<FetchSessionsByGroup>(_onFetchSessionsByGroup);
    on<FetchSessionsByDate>(_onFetchSessionsByDate);
    on<FetchAttendanceBySession>(_onFetchAttendanceBySession);
    on<CreateSessionEvent>(_onCreateSession);
    on<UpdateSessionEvent>(_onUpdateSession);
    on<DeleteSessionEvent>(_onDeleteSession);
    on<SaveAttendanceEvent>(_onSaveAttendance);
    on<UnexemptStudentFromExtraFee>(_onUnexemptStudentFromExtraFee);

    on<FetchTemplatesByGroup>(_onFetchTemplatesByGroup);
    on<CreateTemplateEvent>(_onCreateTemplate);
    on<UpdateTemplateEvent>(_onUpdateTemplate);
    on<DeleteTemplateEvent>(_onDeleteTemplate);
    on<GenerateTodaySessions>(_onGenerateTodaySessions);
    on<GenerateSessionsForDate>(_onGenerateSessionsForDate);
    on<ExemptStudentFromExtraFee>(_onExemptStudentFromExtraFee);
  }

  Future<void> _onUnexemptStudentFromExtraFee(
    UnexemptStudentFromExtraFee event,
    Emitter<AttendanceState> emit,
  ) async {
    final result = await repository.unexemptStudentFromExtraFee(
      sessionId: event.sessionId,
      studentId: event.studentId,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchSessionsByDate(DateTime.now())),
    );
  }

  // ====== إنشاء حصة ======
  Future<void> _onCreateSession(
    CreateSessionEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final result = await repository.createSession(event.session);

    await result.fold(
      (failure) async {
        emit(state.copyWith(errorMessage: failure.message));
      },
      (sessionId) async {
        // ✅ إذا كانت حصة إضافية، طبق المبلغ على الطلاب
        if (event.session.type == 'extra' &&
            event.session.price != null &&
            event.session.price! > 0) {
          final applyResult = await repository.applyExtraFeeToStudents(
            sessionId: sessionId,
            groupId: event.session.groupId,
            price: event.session.price!,
          );
          applyResult.fold(
            (failure) => emit(state.copyWith(errorMessage: failure.message)),
            (_) => add(FetchTodaySessions()),
          );
        } else {
          add(FetchTodaySessions());
        }
      },
    );
  }

  Future<void> _onExemptStudentFromExtraFee(
    ExemptStudentFromExtraFee event,
    Emitter<AttendanceState> emit,
  ) async {
    final result = await repository.exemptStudentFromExtraFee(
      sessionId: event.sessionId,
      studentId: event.studentId,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchTodaySessions()),
    );
  }

  // ====== جلب حصص اليوم ======
  Future<void> _onFetchTodaySessions(
    FetchTodaySessions event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(sessionsState: const Loading()));

    // ✅ الخطوة 1: توليد حصص اليوم أولاً
    await repository.generateSessionsForDate(DateTime.now());
    // ✅ الخطوة 2: جلب حصص اليوم
    final result = await repository.getTodaySessions();
    result.fold(
      (failure) => emit(
        state.copyWith(
          sessionsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (sessions) => emit(
        state.copyWith(
          sessionsState: sessions.isEmpty ? const Empty() : Success(sessions),
        ),
      ),
    );
  }

  // ====== جلب حصص الفوج ======
  Future<void> _onFetchSessionsByGroup(
    FetchSessionsByGroup event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(sessionsState: const Loading()));
    final result = await repository.getSessionsByGroup(event.groupId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          sessionsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (sessions) => emit(
        state.copyWith(
          sessionsState: sessions.isEmpty ? const Empty() : Success(sessions),
        ),
      ),
    );
  }

  // ====== جلب حصص تاريخ معين ======
  Future<void> _onFetchSessionsByDate(
    FetchSessionsByDate event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(sessionsState: const Loading()));
    final result = await repository.getSessionsByDate(event.date);
    result.fold(
      (failure) => emit(
        state.copyWith(
          sessionsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (sessions) => emit(
        state.copyWith(
          sessionsState: sessions.isEmpty ? const Empty() : Success(sessions),
        ),
      ),
    );
  }

  // ====== جلب حضور حصة ======
  Future<void> _onFetchAttendanceBySession(
    FetchAttendanceBySession event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(attendanceState: const Loading()));
    final result = await repository.getAttendanceBySession(event.sessionId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          attendanceState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (attendance) => emit(
        state.copyWith(
          attendanceState: attendance.isEmpty
              ? const Empty()
              : Success(attendance),
        ),
      ),
    );
  }

  // ====== تحديث حصة ======
  Future<void> _onUpdateSession(
    UpdateSessionEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final result = await repository.updateSession(event.session);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchTodaySessions()),
    );
  }

  // ====== حذف حصة ======
  Future<void> _onDeleteSession(
    DeleteSessionEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final result = await repository.deleteSession(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchTodaySessions()),
    );
  }

  // ====== حفظ الحضور ======
  Future<void> _onSaveAttendance(
    SaveAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final result = await repository.saveSessionAttendance(
      sessionId: event.sessionId,
      attendanceList: event.attendanceList,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchAttendanceBySession(event.sessionId)),
    );
  }

  // ====== ✅ توليد الحصص لتاريخ معين ======
  Future<void> _onGenerateSessionsForDate(
    GenerateSessionsForDate event,
    Emitter<AttendanceState> emit,
  ) async {
    final result = await repository.generateSessionsForDate(event.date);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchSessionsByDate(event.date)), // ✅ جلب بعد التوليد
    );
  }

  Future<void> _onFetchTemplatesByGroup(
    FetchTemplatesByGroup event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(templatesState: const Loading()));
    final result = await repository.getTemplatesByGroup(event.groupId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          templatesState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (templates) => emit(
        state.copyWith(
          templatesState: templates.isEmpty
              ? const Empty()
              : Success(templates),
        ),
      ),
    );
  }

  Future<void> _onCreateTemplate(
    CreateTemplateEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final result = await repository.createTemplate(event.template);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchTemplatesByGroup(event.template.groupId)),
    );
  }

  Future<void> _onUpdateTemplate(
    UpdateTemplateEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final result = await repository.updateTemplate(event.template);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchTemplatesByGroup(event.template.groupId)),
    );
  }

  Future<void> _onDeleteTemplate(
    DeleteTemplateEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    // نحتاج معرفة groupId للحذف، لذا سنحتاج إلى تمريره
    // أبسط حل: نمرر groupId في الحدث
    final result = await repository.deleteTemplate(event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => add(FetchTodaySessions()),
    );
  }

  Future<void> _onGenerateTodaySessions(
    GenerateTodaySessions event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(sessionsState: const Loading()));

    final result = await repository.generateSessionsForDate(DateTime.now());

    result.fold(
      (failure) => emit(
        state.copyWith(
          sessionsState: Error(failure.message),
          errorMessage: failure.message,
        ),
      ),
      (_) {
        // ✅ بعد التوليد، نجلب حصص اليوم المحدثة
        add(FetchTodaySessions());
      },
    );
  }
}
