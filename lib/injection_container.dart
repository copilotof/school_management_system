import 'package:get_it/get_it.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/enrollment/data/repositories/enrollment_repository_impl.dart';
import 'package:school_management_system/features/enrollment/data/sources/enrollment_local_source.dart';
import 'package:school_management_system/features/enrollment/domain/repositories/enrollment_repository.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/grades/data/repositories/grade_repository_impl.dart';
import 'package:school_management_system/features/grades/data/sources/grade_local_source.dart';
import 'package:school_management_system/features/grades/data/sources/grade_subject_local_source.dart';
import 'package:school_management_system/features/grades/domain/repositories/grade_repository.dart';
import 'package:school_management_system/features/grades/presentation/bloc/grades_bloc.dart';
import 'package:school_management_system/features/groups/data/repositories/group_repository_impl.dart';
import 'package:school_management_system/features/groups/data/sources/group_local_source.dart';
import 'package:school_management_system/features/groups/domain/repositories/group_repository.dart';
import 'package:school_management_system/features/groups/domain/usecases/create_group.dart';
import 'package:school_management_system/features/groups/domain/usecases/delete_group.dart';
import 'package:school_management_system/features/groups/domain/usecases/get_all_groups.dart';
import 'package:school_management_system/features/groups/domain/usecases/search_groups.dart';
import 'package:school_management_system/features/groups/domain/usecases/update_group.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/students/data/repositories/student_repository_impl.dart';
import 'package:school_management_system/features/students/data/sources/student_local_source.dart';
import 'package:school_management_system/features/students/domain/repositories/student_repository.dart';
import 'package:school_management_system/features/students/domain/usecases/create_student.dart';
import 'package:school_management_system/features/students/domain/usecases/delete_student.dart';
import 'package:school_management_system/features/students/domain/usecases/get_all_students.dart';
import 'package:school_management_system/features/students/domain/usecases/search_students.dart';
import 'package:school_management_system/features/students/domain/usecases/update_student.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:school_management_system/features/subjects/data/sources/subject_local_source.dart';
import 'package:school_management_system/features/subjects/domain/repositories/subject_repository.dart';
import 'package:school_management_system/features/subjects/domain/usecases/create_subject.dart';
import 'package:school_management_system/features/subjects/domain/usecases/delete_subject.dart';
import 'package:school_management_system/features/subjects/domain/usecases/get_all_subjects.dart';
import 'package:school_management_system/features/subjects/domain/usecases/search_subjects.dart';
import 'package:school_management_system/features/subjects/domain/usecases/update_subject.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:school_management_system/features/teachers/data/repositories/teacher_repository_impl.dart';
import 'package:school_management_system/features/teachers/data/sources/teacher_local_source.dart';
import 'package:school_management_system/features/teachers/domain/repositories/teacher_repository.dart';
import 'package:school_management_system/features/teachers/domain/usecases/create_teacher.dart';
import 'package:school_management_system/features/teachers/domain/usecases/delete_teacher.dart';
import 'package:school_management_system/features/teachers/domain/usecases/get_all_teachers.dart';
import 'package:school_management_system/features/teachers/domain/usecases/search_teachers.dart';
import 'package:school_management_system/features/teachers/domain/usecases/update_teacher.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_bloc.dart';

import 'core/database/settings_local_source.dart';
import 'features/attendance/data/repositories/attendance_repository_impl.dart';
import 'features/attendance/data/sources/attendance_local_source.dart';
import 'features/attendance/domain/repositories/attendance_repository.dart';
import 'features/attendance/presentation/bloc/attendance_bloc.dart';
import 'features/finance/data/repositories/finance_repository_impl.dart';
import 'features/finance/data/sources/finance_local_source.dart';
import 'features/finance/domain/repositories/finance_repository.dart';
import 'features/finance/presentation/bloc/finance_bloc.dart';
import 'features/notifications/data/repositories/notification_repository_impl.dart';
import 'features/notifications/data/sources/notification_local_source.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/services/auto_notification_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ====== قاعدة البيانات ======
  if (!getIt.isRegistered<AppDatabase>()) {
    getIt.registerSingleton<AppDatabase>(AppDatabase());
  }

  // ====== الطلاب ======
  if (!getIt.isRegistered<StudentLocalDataSource>()) {
    getIt.registerSingleton<StudentLocalDataSource>(
      StudentLocalDataSource(db: getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<StudentRepository>()) {
    getIt.registerSingleton<StudentRepository>(
      StudentRepositoryImpl(localDataSource: getIt<StudentLocalDataSource>()),
    );
  }
  // ✅ UseCases
  if (!getIt.isRegistered<GetAllStudents>()) {
    getIt.registerFactory(() => GetAllStudents(repository: getIt()));
  }
  if (!getIt.isRegistered<SearchStudents>()) {
    getIt.registerFactory(() => SearchStudents(repository: getIt()));
  }
  if (!getIt.isRegistered<CreateStudent>()) {
    getIt.registerFactory(() => CreateStudent(repository: getIt()));
  }
  if (!getIt.isRegistered<UpdateStudent>()) {
    getIt.registerFactory(() => UpdateStudent(repository: getIt()));
  }
  if (!getIt.isRegistered<DeleteStudent>()) {
    getIt.registerFactory(() => DeleteStudent(repository: getIt()));
  }
  if (!getIt.isRegistered<StudentsBloc>()) {
    getIt.registerFactory(
      () => StudentsBloc(
        getAllStudents: getIt(),
        searchStudents: getIt(),
        createStudent: getIt(),
        updateStudent: getIt(),
        deleteStudent: getIt(),
      ),
    );
  }

  // ====== المواد ======
  if (!getIt.isRegistered<SubjectLocalDataSource>()) {
    getIt.registerSingleton<SubjectLocalDataSource>(
      SubjectLocalDataSource(db: getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<SubjectRepository>()) {
    getIt.registerSingleton<SubjectRepository>(
      SubjectRepositoryImpl(localDataSource: getIt<SubjectLocalDataSource>()),
    );
  }
  if (!getIt.isRegistered<GetAllSubjects>()) {
    getIt.registerFactory(() => GetAllSubjects(repository: getIt()));
  }
  if (!getIt.isRegistered<SearchSubjects>()) {
    getIt.registerFactory(() => SearchSubjects(repository: getIt()));
  }
  if (!getIt.isRegistered<CreateSubject>()) {
    getIt.registerFactory(() => CreateSubject(repository: getIt()));
  }
  if (!getIt.isRegistered<UpdateSubject>()) {
    getIt.registerFactory(() => UpdateSubject(repository: getIt()));
  }
  if (!getIt.isRegistered<DeleteSubject>()) {
    getIt.registerFactory(() => DeleteSubject(repository: getIt()));
  }
  if (!getIt.isRegistered<SubjectsBloc>()) {
    getIt.registerFactory(
      () => SubjectsBloc(
        getAllSubjects: getIt(),
        searchSubjects: getIt(),
        createSubject: getIt(),
        updateSubject: getIt(),
        deleteSubject: getIt(),
      ),
    );
  }

  // ====== المعلمين ======
  if (!getIt.isRegistered<TeacherLocalDataSource>()) {
    getIt.registerSingleton<TeacherLocalDataSource>(
      TeacherLocalDataSource(db: getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<TeacherRepository>()) {
    getIt.registerSingleton<TeacherRepository>(
      TeacherRepositoryImpl(localDataSource: getIt<TeacherLocalDataSource>()),
    );
  }
  if (!getIt.isRegistered<GetAllTeachers>()) {
    getIt.registerFactory(() => GetAllTeachers(repository: getIt()));
  }
  if (!getIt.isRegistered<SearchTeachers>()) {
    getIt.registerFactory(() => SearchTeachers(repository: getIt()));
  }
  if (!getIt.isRegistered<CreateTeacher>()) {
    getIt.registerFactory(() => CreateTeacher(repository: getIt()));
  }
  if (!getIt.isRegistered<UpdateTeacher>()) {
    getIt.registerFactory(() => UpdateTeacher(repository: getIt()));
  }
  if (!getIt.isRegistered<DeleteTeacher>()) {
    getIt.registerFactory(() => DeleteTeacher(repository: getIt()));
  }
  if (!getIt.isRegistered<TeachersBloc>()) {
    getIt.registerFactory(
      () => TeachersBloc(
        getAllTeachers: getIt(),
        searchTeachers: getIt(),
        createTeacher: getIt(),
        updateTeacher: getIt(),
        deleteTeacher: getIt(),
      ),
    );
  }

  // ====== الأفواج ======
  if (!getIt.isRegistered<GroupLocalDataSource>()) {
    getIt.registerSingleton<GroupLocalDataSource>(
      GroupLocalDataSource(db: getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<GroupRepository>()) {
    getIt.registerSingleton<GroupRepository>(
      GroupRepositoryImpl(localDataSource: getIt<GroupLocalDataSource>()),
    );
  }
  if (!getIt.isRegistered<GetAllGroups>()) {
    getIt.registerFactory(() => GetAllGroups(repository: getIt()));
  }
  if (!getIt.isRegistered<SearchGroups>()) {
    getIt.registerFactory(() => SearchGroups(repository: getIt()));
  }
  if (!getIt.isRegistered<CreateGroup>()) {
    getIt.registerFactory(() => CreateGroup(repository: getIt()));
  }
  if (!getIt.isRegistered<UpdateGroup>()) {
    getIt.registerFactory(() => UpdateGroup(repository: getIt()));
  }
  if (!getIt.isRegistered<DeleteGroup>()) {
    getIt.registerFactory(() => DeleteGroup(repository: getIt()));
  }
  if (!getIt.isRegistered<GroupsBloc>()) {
    getIt.registerFactory(
      () => GroupsBloc(
        getAllGroups: getIt(),
        searchGroups: getIt(),
        createGroup: getIt(),
        updateGroup: getIt(),
        deleteGroup: getIt(),
      ),
    );
  }

  // ====== الصفوف ======
  if (!getIt.isRegistered<GradeLocalDataSource>()) {
    getIt.registerSingleton<GradeLocalDataSource>(
      GradeLocalDataSource(db: getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<GradeSubjectLocalDataSource>()) {
    getIt.registerSingleton<GradeSubjectLocalDataSource>(
      GradeSubjectLocalDataSource(db: getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<GradeRepository>()) {
    getIt.registerSingleton<GradeRepository>(
      GradeRepositoryImpl(
        localDataSource: getIt<GradeLocalDataSource>(),
        gradeSubjectLocalDataSource: getIt<GradeSubjectLocalDataSource>(),
      ),
    );
  }
  if (!getIt.isRegistered<GradesBloc>()) {
    getIt.registerFactory(() => GradesBloc(repository: getIt()));
  }

  // ====== التسجيل ======
  if (!getIt.isRegistered<EnrollmentLocalDataSource>()) {
    getIt.registerSingleton<EnrollmentLocalDataSource>(
      EnrollmentLocalDataSource(db: getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<EnrollmentRepository>()) {
    getIt.registerSingleton<EnrollmentRepository>(
      EnrollmentRepositoryImpl(
        localDataSource: getIt<EnrollmentLocalDataSource>(),
      ),
    );
  }
  if (!getIt.isRegistered<EnrollmentBloc>()) {
    getIt.registerFactory(() => EnrollmentBloc(repository: getIt()));
  }

  if (!getIt.isRegistered<FinanceLocalDataSource>()) {
    getIt.registerSingleton<FinanceLocalDataSource>(
      FinanceLocalDataSource(db: getIt<AppDatabase>()),
    );
  }

  if (!getIt.isRegistered<FinanceRepository>()) {
    getIt.registerSingleton<FinanceRepository>(
      FinanceRepositoryImpl(localDataSource: getIt<FinanceLocalDataSource>()),
    );
  }

  if (!getIt.isRegistered<FinanceBloc>()) {
    getIt.registerFactory(
      () => FinanceBloc(
        repository: getIt<FinanceRepository>(),
        notificationRepository: getIt<NotificationRepository>(), // ✅
      ),
    );
  }

  if (!getIt.isRegistered<FinanceLocalDataSource>()) {
    getIt.registerSingleton<FinanceLocalDataSource>(
      FinanceLocalDataSource(db: getIt<AppDatabase>()),
    );
  }

  // في configureDependencies:
  if (!getIt.isRegistered<AttendanceLocalDataSource>()) {
    getIt.registerSingleton<AttendanceLocalDataSource>(
      AttendanceLocalDataSource(db: getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<AttendanceRepository>()) {
    getIt.registerSingleton<AttendanceRepository>(
      AttendanceRepositoryImpl(
        localDataSource: getIt<AttendanceLocalDataSource>(),
        db: getIt<AppDatabase>(),
      ),
    );
  }

  if (!getIt.isRegistered<AttendanceBloc>()) {
    getIt.registerFactory(
      () => AttendanceBloc(
        repository: getIt<AttendanceRepository>(),
        autoNotificationService: getIt<AutoNotificationService>(),
        settingsLocalDataSource: getIt<SettingsLocalDataSource>(),
      ),
    );
  }
  if (!getIt.isRegistered<NotificationLocalDataSource>()) {
    getIt.registerSingleton<NotificationLocalDataSource>(
      NotificationLocalDataSource(db: getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<NotificationRepository>()) {
    getIt.registerSingleton<NotificationRepository>(
      NotificationRepositoryImpl(
        localDataSource: getIt<NotificationLocalDataSource>(),
      ),
    );
  }
  if (!getIt.isRegistered<NotificationBloc>()) {
    getIt.registerFactory(() => NotificationBloc(repository: getIt()));
  }

  if (!getIt.isRegistered<AutoNotificationService>()) {
    getIt.registerSingleton<AutoNotificationService>(
      AutoNotificationService(db: getIt<AppDatabase>()),
    );
  }

  // ✅ تسجيل SettingsLocalDataSource
  if (!getIt.isRegistered<SettingsLocalDataSource>()) {
    getIt.registerSingleton<SettingsLocalDataSource>(
      SettingsLocalDataSource(db: getIt<AppDatabase>()),
    );
  }
}
