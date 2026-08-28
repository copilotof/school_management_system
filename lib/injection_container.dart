import 'package:get_it/get_it.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/students/data/repositories/student_repository_impl.dart';
import 'package:school_management_system/features/students/data/sources/student_local_source.dart';
import 'package:school_management_system/features/students/domain/repositories/student_repository.dart';
import 'package:school_management_system/features/students/domain/usecases/create_student.dart';
import 'package:school_management_system/features/students/domain/usecases/delete_student.dart';
import 'package:school_management_system/features/students/domain/usecases/get_all_students.dart';
import 'package:school_management_system/features/students/domain/usecases/search_students.dart';
import 'package:school_management_system/features/students/domain/usecases/update_student.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';

import 'features/subjects/data/repositories/subject_repository_impl.dart';
import 'features/subjects/data/sources/subject_local_source.dart';
import 'features/subjects/domain/repositories/subject_repository.dart';
import 'features/subjects/domain/usecases/create_subject.dart';
import 'features/subjects/domain/usecases/delete_subject.dart';
import 'features/subjects/domain/usecases/get_all_subjects.dart';
import 'features/subjects/domain/usecases/search_subjects.dart';
import 'features/subjects/domain/usecases/update_subject.dart';
import 'features/subjects/presentation/bloc/subjects_bloc.dart';

import 'package:school_management_system/features/teachers/data/repositories/teacher_repository_impl.dart';
import 'package:school_management_system/features/teachers/data/sources/teacher_local_source.dart';
import 'package:school_management_system/features/teachers/domain/repositories/teacher_repository.dart';
import 'package:school_management_system/features/teachers/domain/usecases/create_teacher.dart';
import 'package:school_management_system/features/teachers/domain/usecases/delete_teacher.dart';
import 'package:school_management_system/features/teachers/domain/usecases/get_all_teachers.dart';
import 'package:school_management_system/features/teachers/domain/usecases/search_teachers.dart';
import 'package:school_management_system/features/teachers/domain/usecases/update_teacher.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // قاعدة البيانات
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  // مصدر البيانات
  final studentLocalDataSource = StudentLocalDataSource(db: database);
  getIt.registerSingleton<StudentLocalDataSource>(studentLocalDataSource);

  // المستودع
  final studentRepository = StudentRepositoryImpl(
    localDataSource: studentLocalDataSource,
  );
  getIt.registerSingleton<StudentRepository>(studentRepository);

  // حالات الاستخدام - ✅ استخدام named parameters
  getIt.registerFactory(() => GetAllStudents(repository: getIt()));
  getIt.registerFactory(() => SearchStudents(repository: getIt()));
  getIt.registerFactory(() => CreateStudent(repository: getIt()));
  getIt.registerFactory(() => UpdateStudent(repository: getIt()));
  getIt.registerFactory(() => DeleteStudent(repository: getIt()));

  // BLoC
  getIt.registerFactory(
    () => StudentsBloc(
      getAllStudents: getIt(),
      searchStudents: getIt(),
      createStudent: getIt(),
      updateStudent: getIt(),
      deleteStudent: getIt(),
    ),
  );

  final subjectLocalDataSource = SubjectLocalDataSource(db: database);
  getIt.registerSingleton<SubjectLocalDataSource>(subjectLocalDataSource);

  final subjectRepository = SubjectRepositoryImpl(
    localDataSource: subjectLocalDataSource,
  );
  getIt.registerSingleton<SubjectRepository>(subjectRepository);

  getIt.registerFactory(() => GetAllSubjects(repository: getIt()));
  getIt.registerFactory(() => SearchSubjects(repository: getIt()));
  getIt.registerFactory(() => CreateSubject(repository: getIt()));
  getIt.registerFactory(() => UpdateSubject(repository: getIt()));
  getIt.registerFactory(() => DeleteSubject(repository: getIt()));

  getIt.registerFactory(
    () => SubjectsBloc(
      getAllSubjects: getIt(),
      searchSubjects: getIt(),
      createSubject: getIt(),
      updateSubject: getIt(),
      deleteSubject: getIt(),
    ),
  );

  final teacherLocalDataSource = TeacherLocalDataSource(db: database);
  getIt.registerSingleton<TeacherLocalDataSource>(teacherLocalDataSource);

  final teacherRepository = TeacherRepositoryImpl(
    localDataSource: teacherLocalDataSource,
  );
  getIt.registerSingleton<TeacherRepository>(teacherRepository);

  getIt.registerFactory(() => GetAllTeachers(repository: getIt()));
  getIt.registerFactory(() => SearchTeachers(repository: getIt()));
  getIt.registerFactory(() => CreateTeacher(repository: getIt()));
  getIt.registerFactory(() => UpdateTeacher(repository: getIt()));
  getIt.registerFactory(() => DeleteTeacher(repository: getIt()));

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
