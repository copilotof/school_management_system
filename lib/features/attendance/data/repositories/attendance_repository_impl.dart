import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/attendance/data/models/attendance_mapper.dart';
import 'package:school_management_system/features/attendance/data/models/schedule_template_mapper.dart';
import 'package:school_management_system/features/attendance/data/sources/attendance_local_source.dart';
import 'package:school_management_system/features/attendance/domain/entities/attendance_entity.dart';
import 'package:school_management_system/features/attendance/domain/entities/schedule_template_entity.dart';
import 'package:school_management_system/features/attendance/domain/entities/session_entity.dart';
import 'package:school_management_system/features/attendance/domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceLocalDataSource localDataSource;
  final AppDatabase db;

  AttendanceRepositoryImpl({required this.localDataSource, required this.db});

  // ====== الحصص ======
  @override
  Future<Either<Failure, List<SessionEntity>>> getAllSessions() async {
    try {
      final rows = await localDataSource.getAllSessions();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SessionEntity>>> getSessionsByGroup(
    int groupId,
  ) async {
    try {
      final rows = await localDataSource.getSessionsByGroup(groupId);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SessionEntity>>> getTodaySessions() async {
    try {
      final rows = await localDataSource.getTodaySessions();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SessionEntity>>> getSessionsByDate(
    DateTime date,
  ) async {
    try {
      final rows = await localDataSource.getSessionsByDate(date);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, SessionEntity?>> getSessionById(int id) async {
    try {
      final row = await localDataSource.getSessionById(id);
      return Right(row?.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, SessionEntity?>> getNextSession(
    int groupId,
    DateTime after,
  ) async {
    try {
      final session =
          await (db.select(db.sessions)
                ..where(
                  (t) =>
                      t.groupId.equals(groupId) &
                      t.sessionDate.isBiggerThanValue(after),
                )
                ..orderBy([(t) => OrderingTerm(expression: t.sessionDate)])
                ..limit(1))
              .getSingleOrNull();
      return Right(session?.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createSession(SessionEntity session) async {
    try {
      final companion = SessionMapper.fromEntity(session);
      return Right(await localDataSource.createSession(companion));
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateSession(SessionEntity session) async {
    try {
      final row = await localDataSource.getSessionById(session.id!);
      if (row == null) return const Left(NotFoundFailure('الحصة غير موجودة'));
      final updated = row.copyWith(
        groupId: session.groupId,
        sessionDate: session.sessionDate,
        startTime: session.startTime,
        endTime: session.endTime,
        type: session.type,
        status: session.status,
        lessonTopic: Value(session.lessonTopic),
        teacherNotes: Value(session.teacherNotes),
        homework: Value(session.homework),
        cancelReason: Value(session.cancelReason),
        isPaid: session.isPaid,
        price: Value(session.price),
        updatedAt: DateTime.now(),
      );
      return Right(await localDataSource.updateSession(updated));
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteSession(int id) async {
    try {
      // حذف الحضور المرتبط أولاً
      await (db.delete(
        db.attendance,
      )..where((t) => t.sessionId.equals(id))).go();
      // حذف العمليات المالية المرتبطة بالحصة
      await (db.delete(db.payments)..where((t) => t.sessionId.equals(id))).go();
      // حذف الحصة
      return Right(await localDataSource.deleteSession(id) > 0);
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getPresentCount(int sessionId) async {
    try {
      return Right(await localDataSource.getPresentCount(sessionId));
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  // ====== الحضور ======
  @override
  Future<Either<Failure, List<AttendanceEntity>>> getAttendanceBySession(
    int sessionId,
  ) async {
    try {
      final rows = await localDataSource.getAttendanceBySession(sessionId);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceEntity>>> getAttendanceByStudent(
    int studentId,
  ) async {
    try {
      final rows = await localDataSource.getAttendanceByStudent(studentId);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> saveSessionAttendance({
    required int sessionId,
    required List<AttendanceEntity> attendanceList,
  }) async {
    try {
      final companions = attendanceList
          .map((a) => AttendanceMapper.fromEntity(a))
          .toList();
      await localDataSource.saveSessionAttendance(
        sessionId: sessionId,
        attendanceList: companions,
      );
      return const Right(true);
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getAbsenceCount(int studentId) async {
    try {
      return Right(await localDataSource.getAbsenceCount(studentId));
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  /// ✅ إلغاء الإعفاء
  @override
  Future<Either<Failure, void>> unexemptStudentFromExtraFee({
    required int sessionId,
    required int studentId,
  }) async {
    try {
      final payment =
          await (db.select(db.payments)..where(
                (t) =>
                    t.studentId.equals(studentId) &
                    t.sessionId.equals(sessionId) &
                    t.type.equals('extra'),
              ))
              .getSingleOrNull();

      if (payment == null) {
        return const Left(NotFoundFailure('لا توجد عملية مالية لهذا الطالب'));
      }

      // ✅ إلغاء الإعفاء: المدفوع = 0، المتبقي = الأصلي
      final updated = payment.copyWith(
        amount: 0,
        remainingAmount: payment.originalAmount,
        notes: Value('إلغاء الإعفاء - مستحق'),
        updatedAt: DateTime.now(),
      );

      await db.update(db.payments).replace(updated);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('فشل في إلغاء الإعفاء: $e'));
    }
  }

  // ====== توليد الحصص ======
  @override
  Future<Either<Failure, void>> generateSessionsForDate(DateTime date) async {
    try {
      final groups = await db.select(db.groups).get();
      final dayOfWeek = date.weekday % 7;

      for (final group in groups) {
        final exists = await localDataSource.sessionExistsForDate(
          group.id,
          date,
        );
        if (exists) continue;

        final templates = await localDataSource.getTemplatesByGroup(group.id);
        for (final template in templates) {
          if (template.dayOfWeek != dayOfWeek) continue;

          final session = SessionEntity(
            groupId: group.id,
            templateId: template.id,
            sessionDate: DateTime(date.year, date.month, date.day),
            startTime: DateTime(
              date.year,
              date.month,
              date.day,
              template.startTime.hour,
              template.startTime.minute,
            ),
            endTime: DateTime(
              date.year,
              date.month,
              date.day,
              template.endTime.hour,
              template.endTime.minute,
            ),
            type: 'regular',
            status: 'scheduled',
          );
          await localDataSource.createSession(
            SessionMapper.fromEntity(session),
          );
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> sessionExistsForDate(
    int groupId,
    DateTime date,
  ) async {
    try {
      return Right(await localDataSource.sessionExistsForDate(groupId, date));
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  // ====== القوالب الأسبوعية ======
  @override
  Future<Either<Failure, List<ScheduleTemplateEntity>>> getTemplatesByGroup(
    int groupId,
  ) async {
    try {
      final rows = await localDataSource.getTemplatesByGroup(groupId);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createTemplate(
    ScheduleTemplateEntity template,
  ) async {
    try {
      final companion = ScheduleTemplateMapper.fromEntity(template);
      return Right(await localDataSource.createTemplate(companion));
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateTemplate(
    ScheduleTemplateEntity template,
  ) async {
    try {
      final row = await localDataSource.getTemplateById(template.id!);
      if (row == null) return const Left(NotFoundFailure('القالب غير موجود'));
      final updated = row.copyWith(
        dayOfWeek: template.dayOfWeek,
        startTime: template.startTime,
        endTime: template.endTime,
        location: Value(template.location),
        isActive: template.isActive,
      );
      return Right(await localDataSource.updateTemplate(updated));
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteTemplate(int id) async {
    try {
      return Right(await localDataSource.deleteTemplate(id) > 0);
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  // ============================================================
  // ✅ الحصة الإضافية المدفوعة
  // ============================================================

  /// ✅ تطبيق الحصة الإضافية على كل طلاب الفوج
  @override
  Future<Either<Failure, void>> applyExtraFeeToStudents({
    required int sessionId,
    required int groupId,
    required double price,
  }) async {
    try {
      debugPrint(
        '🟡 applyExtraFeeToStudents: sessionId=$sessionId, groupId=$groupId, price=$price',
      );

      // 1. جلب كل طلاب الفوج
      final enrollments =
          await (db.select(db.enrollments)..where(
                (t) => t.groupId.equals(groupId) & t.status.equals('active'),
              ))
              .get();

      debugPrint('   - عدد الطلاب: ${enrollments.length}');

      // 2. إنشاء عملية مالية لكل طالب
      for (final enrollment in enrollments) {
        // التحقق من عدم وجود عملية مالية سابقة
        final existing =
            await (db.select(db.payments)..where(
                  (t) =>
                      t.studentId.equals(enrollment.studentId) &
                      t.sessionId.equals(sessionId) &
                      t.type.equals('extra'),
                ))
                .getSingleOrNull();

        if (existing != null) {
          debugPrint('   - الطالب ${enrollment.studentId}: لديه عملية مسبقة');
          continue;
        }

        // إنشاء عملية مالية
        final payment = PaymentsCompanion.insert(
          studentId: enrollment.studentId,
          groupId: Value(groupId),
          sessionId: Value(sessionId),
          type: 'extra',
          originalAmount: price,
          amount: 0,
          remainingAmount: Value(price),
          paymentDate: Value(DateTime.now()),
          method: Value('cash'),
          receiptNumber:
              'EXTRA-$sessionId-${enrollment.studentId}-${DateTime.now().millisecondsSinceEpoch}',
          notes: Value('حصة إضافية'),
        );

        await db.into(db.payments).insert(payment);
        debugPrint('   ✅ عملية مالية للطالب ${enrollment.studentId}');
      }

      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('🔴 خطأ: $e');
      debugPrint('Stack: $stackTrace');
      return Left(DatabaseFailure('فشل في تطبيق الحصة الإضافية: $e'));
    }
  }

  /// ✅ إعفاء طالب من الحصة الإضافية
  @override
  Future<Either<Failure, void>> exemptStudentFromExtraFee({
    required int sessionId,
    required int studentId,
  }) async {
    try {
      final payment =
          await (db.select(db.payments)..where(
                (t) =>
                    t.studentId.equals(studentId) &
                    t.sessionId.equals(sessionId) &
                    t.type.equals('extra'),
              ))
              .getSingleOrNull();

      if (payment == null) {
        return const Left(NotFoundFailure('لا توجد عملية مالية لهذا الطالب'));
      }

      // ✅ الإعفاء: المدفوع = الأصلي، المتبقي = 0
      final updated = payment.copyWith(
        amount: payment.originalAmount,
        remainingAmount: 0,
        notes: Value('إعفاء من الحصة الإضافية'),
        updatedAt: DateTime.now(),
      );

      await db.update(db.payments).replace(updated);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('فشل في إعفاء الطالب: $e'));
    }
  }

  /// ✅ جلب المتبقي لطالب في حصة إضافية
  @override
  Future<Either<Failure, double>> getStudentExtraFeeRemaining({
    required int sessionId,
    required int studentId,
  }) async {
    try {
      final payment =
          await (db.select(db.payments)..where(
                (t) =>
                    t.studentId.equals(studentId) &
                    t.sessionId.equals(sessionId) &
                    t.type.equals('extra'),
              ))
              .getSingleOrNull();

      if (payment == null) return const Right(0);
      return Right(payment.remainingAmount);
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceEntity>>>
  getAttendanceByStudentAndDateRange({
    required int studentId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final rows =
          await (db.select(db.attendance)
                ..where(
                  (t) =>
                      t.studentId.equals(studentId) &
                      t.createdAt.isBiggerOrEqualValue(from) &
                      t.createdAt.isSmallerOrEqualValue(to),
                )
                ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
              .get();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceEntity>>>
  getAttendanceByGroupAndDateRange({
    required int groupId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      // جلب حصص الفوج في الفترة
      final sessions =
          await (db.select(db.sessions)..where(
                (t) =>
                    t.groupId.equals(groupId) &
                    t.sessionDate.isBiggerOrEqualValue(from) &
                    t.sessionDate.isSmallerOrEqualValue(to),
              ))
              .get();

      if (sessions.isEmpty) return const Right([]);

      final sessionIds = sessions.map((s) => s.id).toList();

      // جلب الحضور لهذه الحصص
      final rows = await (db.select(
        db.attendance,
      )..where((t) => t.sessionId.isIn(sessionIds))).get();

      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل: $e'));
    }
  }
}
