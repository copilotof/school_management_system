import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 📁 قاعدة البيانات الرئيسية - Drift (SQLite)

// ============== جدول الطلاب ==============
@DataClassName('Student')
class Students extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get schoolId => integer().withDefault(const Constant(1))();
  IntColumn get guardianId => integer().nullable()();
  TextColumn get studentCode => text().unique()();
  TextColumn get firstName => text().withLength(min: 1, max: 150)();
  TextColumn get lastName => text().withLength(min: 1, max: 150)();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get gender => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  RealColumn get registrationFee =>
      real().withDefault(const Constant(0))(); // ✅
}

// ============== جدول المدارس ==============
@DataClassName('School')
class Schools extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get logoPath => text().nullable()();
  TextColumn get defaultLanguage => text().withDefault(const Constant('ar'))();
  TextColumn get timezone =>
      text().withDefault(const Constant('Africa/Algiers'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول السنوات الدراسية ==============
@DataClassName('AcademicYear')
class AcademicYears extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get schoolId => integer().withDefault(const Constant(1))();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {schoolId, name},
  ];
}

// ============== جدول المواد الدراسية ==============
@DataClassName('Subject')
class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get schoolId => integer().withDefault(const Constant(1))();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get code => text().nullable()();
  TextColumn get description => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول المعلمين ==============
@DataClassName('Teacher')
class Teachers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get schoolId => integer().withDefault(const Constant(1))();
  TextColumn get fullName => text().withLength(min: 1, max: 255)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get specialization => text().nullable()();
  DateTimeColumn get hireDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول أولياء الأمور ==============
@DataClassName('Guardian')
class Guardians extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get schoolId => integer().withDefault(const Constant(1))();
  TextColumn get fullName => text().withLength(min: 1, max: 255)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get relationship => text().nullable()();
  TextColumn get address => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول المستويات الدراسية ==============
@DataClassName('AcademicLevel')
class AcademicLevels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول الصفوف الدراسية ==============
@DataClassName('Grade')
class Grades extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get academicLevelId =>
      integer().nullable().references(AcademicLevels, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول علاقة الصفوف والمواد ==============
@DataClassName('GradeSubject')
class GradeSubjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gradeId => integer().references(Grades, #id)();
  IntColumn get subjectId => integer().references(Subjects, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {gradeId, subjectId}, // لا يمكن تكرار نفس المادة لنفس الصف
  ];
}

// ============== جدول الأفواج (محدث) ==============
@DataClassName('Group')
class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer().nullable()();
  IntColumn get teacherId => integer().nullable()();
  IntColumn get academicLevelId =>
      integer().nullable()(); // ✅ المستوى (اختياري)
  IntColumn get gradeId => integer().nullable()(); // ✅ الصف (اختياري)
  TextColumn get name => text().withLength(min: 1, max: 255)();
  IntColumn get maxStudents => integer().withDefault(const Constant(30))();
  RealColumn get monthlyFee => real().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول التسجيلات ==============
@DataClassName('Enrollment')
class Enrollments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get schoolId => integer().withDefault(const Constant(1))();
  IntColumn get studentId => integer()();
  IntColumn get groupId => integer()();
  DateTimeColumn get enrollmentDate =>
      dateTime().withDefault(currentDateAndTime)();
  RealColumn get registrationFee => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول الحضور ==============
@DataClassName('Session')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer()();
  IntColumn get templateId => integer().nullable()(); // ✅ للقالب
  DateTimeColumn get sessionDate => dateTime()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get type =>
      text().withDefault(const Constant('regular'))(); // regular, makeup, extra
  TextColumn get status => text().withDefault(
    const Constant('scheduled'),
  )(); // scheduled, in_progress, completed, cancelled, postponed
  TextColumn get lessonTopic => text().nullable()();
  TextColumn get teacherNotes => text().nullable()();
  TextColumn get homework => text().nullable()();
  TextColumn get cancelReason => text().nullable()(); // ✅ سبب الإلغاء
  BoolColumn get isPaid =>
      boolean().withDefault(const Constant(false))(); // ✅ للحصة الإضافية
  RealColumn get price => real().nullable()(); // ✅ سعر الحصة الإضافية
  TextColumn get paymentStatus =>
      text().nullable()(); // ✅ unpaid, partial, paid, exempted
  RealColumn get paidAmount =>
      real().withDefault(const Constant(0))(); // ✅ المدفوع
  RealColumn get remainingAmount =>
      real().withDefault(const Constant(0))(); // ✅ المتبقي
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول القوالب الأسبوعية ==============
@DataClassName('ScheduleTemplate')
class ScheduleTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer()();
  IntColumn get dayOfWeek => integer()(); // 0=الأحد، 1=الإثنين... 6=السبت
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get location => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول المستحقات ==============
@DataClassName('Invoice')
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get schoolId => integer().withDefault(const Constant(1))();
  TextColumn get invoiceNumber => text().unique()();
  IntColumn get studentId => integer()();
  IntColumn get groupId => integer().nullable()();
  IntColumn get sessionId => integer().nullable()();
  TextColumn get type =>
      text()(); // registration, monthly, extra_session, custom
  TextColumn get description => text()();
  RealColumn get amount => real()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('unpaid'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول الخصومات ==============
@DataClassName('Discount')
class Discounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get schoolId => integer().withDefault(const Constant(1))();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get description => text().nullable()();
  RealColumn get percentage => real()();
  TextColumn get conditions => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول الاختبارات ==============
@DataClassName('Exam')
class Exams extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get schoolId => integer().withDefault(const Constant(1))();
  IntColumn get groupId => integer()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  DateTimeColumn get examDate => dateTime()();
  DateTimeColumn get startTime => dateTime().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get type => text()();
  RealColumn get totalMarks => real().nullable()();
  BoolColumn get isExternal => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول نتائج الاختبارات ==============
@DataClassName('ExamResult')
class ExamResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get schoolId => integer().withDefault(const Constant(1))();
  IntColumn get examId => integer()();
  IntColumn get studentId => integer()();
  RealColumn get score => real().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get recordedBy => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {examId, studentId},
  ];
}

// ============== جدول الإشعارات ==============
@DataClassName('Notification')
class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get type => text()(); // attendance, payment, session, general
  TextColumn get recipientType => text()(); // student, guardian, teacher, all
  IntColumn get recipientId => integer().nullable()();
  TextColumn get channel =>
      text().withDefault(const Constant('in_app'))(); // in_app, sms, email
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  TextColumn get metadata => text().nullable()(); // JSON للبيانات الإضافية
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول سجل العمليات ==============
@DataClassName('AuditLog')
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get schoolId => integer().withDefault(const Constant(1))();
  IntColumn get userId => integer().nullable()();
  TextColumn get action => text().withLength(min: 1, max: 100)();
  TextColumn get entityType => text().withLength(min: 1, max: 100)();
  IntColumn get entityId => integer().nullable()();
  TextColumn get oldValues => text().nullable()();
  TextColumn get newValues => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول الدفعات ==============
@DataClassName('Payment')
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer()();
  IntColumn get groupId => integer().nullable()(); // ✅ الفوج
  IntColumn get sessionId => integer().nullable()();
  TextColumn get type => text()(); // monthly, registration, advance, extra
  TextColumn get monthYear => text().nullable()(); // "2025-09" للشهرية
  RealColumn get amount => real()(); // المبلغ المدفوع
  RealColumn get originalAmount => real()(); // المبلغ الأصلي
  RealColumn get remainingAmount =>
      real().withDefault(const Constant(0))(); // المتبقي
  DateTimeColumn get paymentDate =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  TextColumn get receiptNumber => text().unique()();
  TextColumn get notes => text().nullable()();
  IntColumn get recordedBy => integer().nullable()();
  IntColumn get parentPaymentId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول الدفعات الإضافية ==============
@DataClassName('ExtraFee')
class ExtraFees extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer()();
  TextColumn get description => text()();
  RealColumn get totalAmount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get remainingAmount => real()();
  TextColumn get status => text().withDefault(const Constant('unpaid'))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول الإعفاءات ==============
@DataClassName('Exemption')
class Exemptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer()();
  TextColumn get type => text()(); // full, partial
  RealColumn get amount => real()();
  TextColumn get monthYear => text().nullable()();
  IntColumn get extraFeeId => integer().nullable()();
  TextColumn get reason => text()();
  IntColumn get authorizedBy => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== جدول إعدادات الرسوم ==============
@DataClassName('FeeSetting')
class FeeSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  BoolColumn get registrationFeeEnabled =>
      boolean().withDefault(const Constant(false))();
  RealColumn get registrationFeeAmount =>
      real().withDefault(const Constant(0))();
  RealColumn get discount3Months => real().withDefault(const Constant(0))();
  RealColumn get discount6Months => real().withDefault(const Constant(0))();
  RealColumn get discount12Months => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('AttendanceRecord')
class Attendance extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer()();
  IntColumn get studentId => integer()();
  TextColumn get status => text()(); // ✅ present, absent, late فقط
  DateTimeColumn get checkInTime => dateTime().nullable()();
  IntColumn get recordedBy => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {sessionId, studentId},
  ];
}

@DataClassName('SystemSetting')
class SystemSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ============== قاعدة البيانات ==============
@DriftDatabase(
  tables: [
    Schools,
    AcademicYears,
    AcademicLevels,
    Grades,
    GradeSubjects,
    Subjects,
    Teachers,
    Guardians,
    Students,
    Groups,
    Enrollments,
    ScheduleTemplates,
    Sessions,
    Attendance,
    Invoices,
    Payments,
    Discounts,
    Exemptions,
    Exams,
    ExamResults,
    Notifications,
    AuditLogs,
    ExtraFees, // ✅
    FeeSettings, // ✅
    SystemSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // إضافة عمود group_id إذا لم يكن موجوداً
        await m.addColumn(enrollments, enrollments.groupId);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'school_management_db.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
