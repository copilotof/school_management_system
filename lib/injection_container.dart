import 'package:get_it/get_it.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/students/data/repositories/student_repository_impl.dart';
import 'package:school_management_system/features/students/data/sources/student_local_source.dart';
import 'package:school_management_system/features/students/domain/repositories/student_repository.dart';

/// 📁 حقن التبعيات

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // قاعدة البيانات
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  // طبقة الطلاب
  final studentLocalDataSource = StudentLocalDataSource(db: database);
  getIt.registerSingleton<StudentLocalDataSource>(studentLocalDataSource);

  final studentRepository = StudentRepositoryImpl(
    localDataSource: studentLocalDataSource,
  );
  getIt.registerSingleton<StudentRepository>(studentRepository);
}
