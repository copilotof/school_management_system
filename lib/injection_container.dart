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
}
