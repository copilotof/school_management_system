import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:school_management_system/core/database/app_database.dart';

/// 📁 مصدر بيانات الحضور والحصص

class AttendanceLocalDataSource {
  final AppDatabase db;

  AttendanceLocalDataSource({required this.db});

  // ====== الحصص ======

  Future<List<Session>> getAllSessions() async {
    return await (db.select(db.sessions)..orderBy([
          (t) =>
              OrderingTerm(expression: t.sessionDate, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<List<Session>> getSessionsByGroup(int groupId) async {
    return await (db.select(db.sessions)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.sessionDate,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  /*   Future<List<Session>> getTodaySessions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    debugPrint('🟡 getTodaySessions: من $startOfDay إلى $endOfDay');

    final result =
        await (db.select(db.sessions)
              ..where(
                (t) => t.sessionDate.isBetweenValues(startOfDay, endOfDay),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.startTime)]))
            .get();

    debugPrint('🟢 getTodaySessions: ${result.length} حصة');
    for (final s in result) {
      debugPrint(
        '   - id=${s.id}, groupId=${s.groupId}, date=${s.sessionDate}, start=${s.startTime}, end=${s.endTime}',
      );
    }

    return result;
  }
 */
  /// ✅ جلب حصص اليوم
  Future<List<Session>> getTodaySessions() async {
    return getSessionsByDate(DateTime.now());
  }

  Future<Session?> getSessionById(int id) async {
    return await (db.select(
      db.sessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> createSession(SessionsCompanion session) async {
    return await db.into(db.sessions).insert(session);
  }

  Future<bool> updateSession(Session session) async {
    return await db.update(db.sessions).replace(session);
  }

  Future<int> deleteSession(int id) async {
    return await (db.delete(db.sessions)..where((t) => t.id.equals(id))).go();
  }

  // ====== الحضور ======

  Future<List<AttendanceRecord>> getAttendanceBySession(int sessionId) async {
    return await (db.select(
      db.attendance,
    )..where((t) => t.sessionId.equals(sessionId))).get();
  }

  Future<List<AttendanceRecord>> getAttendanceByStudent(int studentId) async {
    return await (db.select(
      db.attendance,
    )..where((t) => t.studentId.equals(studentId))).get();
  }

  Future<AttendanceRecord?> getAttendance(int sessionId, int studentId) async {
    return await (db.select(db.attendance)..where(
          (t) => t.sessionId.equals(sessionId) & t.studentId.equals(studentId),
        ))
        .getSingleOrNull();
  }

  Future<int> createAttendance(AttendanceCompanion attendance) async {
    return await db.into(db.attendance).insert(attendance);
  }

  Future<bool> updateAttendance(AttendanceRecord attendance) async {
    return await db.update(db.attendance).replace(attendance);
  }

  Future<int> deleteAttendance(int id) async {
    return await (db.delete(db.attendance)..where((t) => t.id.equals(id))).go();
  }

  Future<void> saveSessionAttendance({
    required int sessionId,
    required List<AttendanceCompanion> attendanceList,
  }) async {
    await db.transaction(() async {
      await (db.delete(
        db.attendance,
      )..where((t) => t.sessionId.equals(sessionId))).go();
      for (final attendance in attendanceList) {
        await db.into(db.attendance).insert(attendance);
      }
    });
  }

  Future<int> getPresentCount(int sessionId) async {
    final attendance =
        await (db.select(db.attendance)..where(
              (t) => t.sessionId.equals(sessionId) & t.status.equals('present'),
            ))
            .get();
    return attendance.length;
  }

  Future<int> getAbsenceCount(int studentId) async {
    final absences =
        await (db.select(db.attendance)..where(
              (t) =>
                  t.studentId.equals(studentId) &
                  (t.status.equals('absent') | t.status.equals('unexcused')),
            ))
            .get();
    return absences.length;
  }

  /// ✅ جلب قوالب الجدول الأسبوعي لفوج
  Future<List<ScheduleTemplate>> getScheduleTemplates(int groupId) async {
    return await (db.select(
      db.scheduleTemplates,
    )..where((t) => t.groupId.equals(groupId) & t.isActive.equals(true))).get();
  }

  /// ✅ التحقق من وجود حصة لفوج في تاريخ معين
  Future<bool> sessionExistsForDate(int groupId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final sessions =
        await (db.select(db.sessions)..where(
              (t) =>
                  t.groupId.equals(groupId) &
                  t.sessionDate.isBetweenValues(startOfDay, endOfDay),
            ))
            .get();
    debugPrint(
      '   sessionExistsForDate(groupId=$groupId, date=$date): ${sessions.isNotEmpty}',
    );

    return sessions.isNotEmpty;
  }

  /// ✅ جلب حصص تاريخ معين
  Future<List<Session>> getSessionsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return await (db.select(db.sessions)
          ..where((t) => t.sessionDate.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime)]))
        .get();
  }

  // ====== القوالب الأسبوعية ======

  Future<List<ScheduleTemplate>> getTemplatesByGroup(int groupId) async {
    return await (db.select(db.scheduleTemplates)
          ..where((t) => t.groupId.equals(groupId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.dayOfWeek)]))
        .get();
  }

  /// ✅ جلب كل الأفواج
  Future<List<Group>> getAllGroups() async {
    return await db.select(db.groups).get();
  }

  Future<ScheduleTemplate?> getTemplateById(int id) async {
    return await (db.select(
      db.scheduleTemplates,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> createTemplate(ScheduleTemplatesCompanion template) async {
    return await db.into(db.scheduleTemplates).insert(template);
  }

  Future<bool> updateTemplate(ScheduleTemplate template) async {
    return await db.update(db.scheduleTemplates).replace(template);
  }

  Future<int> deleteTemplate(int id) async {
    return await (db.delete(
      db.scheduleTemplates,
    )..where((t) => t.id.equals(id))).go();
  }
}
