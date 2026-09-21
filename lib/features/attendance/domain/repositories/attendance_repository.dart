import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/attendance/domain/entities/attendance_entity.dart';
import 'package:school_management_system/features/attendance/domain/entities/session_entity.dart';

import '../entities/schedule_template_entity.dart';

/// 📁 واجهة مستودع الحضور والحصص
abstract class AttendanceRepository {
  // الحصص
  Future<Either<Failure, List<SessionEntity>>> getAllSessions();
  Future<Either<Failure, List<SessionEntity>>> getSessionsByGroup(int groupId);
  Future<Either<Failure, List<SessionEntity>>> getTodaySessions();
  Future<Either<Failure, List<SessionEntity>>> getSessionsByDate(DateTime date);
  Future<Either<Failure, SessionEntity?>> getSessionById(int id);
  Future<Either<Failure, int>> createSession(
    SessionEntity session,
  ); // ✅ يرجع int
  Future<Either<Failure, bool>> updateSession(SessionEntity session);
  Future<Either<Failure, bool>> deleteSession(int id);
  Future<Either<Failure, int>> getPresentCount(int sessionId);
  Future<Either<Failure, void>> generateSessionsForDate(DateTime date);
  Future<Either<Failure, bool>> sessionExistsForDate(
    int groupId,
    DateTime date,
  );

  Future<Either<Failure, void>> unexemptStudentFromExtraFee({
    required int sessionId,
    required int studentId,
  });

  // الحضور
  Future<Either<Failure, List<AttendanceEntity>>> getAttendanceBySession(
    int sessionId,
  );
  Future<Either<Failure, List<AttendanceEntity>>> getAttendanceByStudent(
    int studentId,
  );
  Future<Either<Failure, bool>> saveSessionAttendance({
    required int sessionId,
    required List<AttendanceEntity> attendanceList,
  });
  Future<Either<Failure, int>> getAbsenceCount(int studentId);

  // القوالب الأسبوعية
  Future<Either<Failure, List<ScheduleTemplateEntity>>> getTemplatesByGroup(
    int groupId,
  );
  Future<Either<Failure, int>> createTemplate(ScheduleTemplateEntity template);
  Future<Either<Failure, bool>> updateTemplate(ScheduleTemplateEntity template);
  Future<Either<Failure, bool>> deleteTemplate(int id);

  // ✅ جديد: الحصة الإضافية المدفوعة
  Future<Either<Failure, void>> applyExtraFeeToStudents({
    required int sessionId,
    required int groupId,
    required double price,
  });

  Future<Either<Failure, void>> exemptStudentFromExtraFee({
    required int sessionId,
    required int studentId,
  });

  Future<Either<Failure, double>> getStudentExtraFeeRemaining({
    required int sessionId,
    required int studentId,
  });
}
