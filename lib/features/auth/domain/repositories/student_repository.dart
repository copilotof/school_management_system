import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

/// 📁 واجهة مستودع الطالب
/// تحدد العمليات المتاحة في طبقة المجال
/// تستخدم Either<Failure, T> للتعامل مع الأخطاء

abstract class StudentRepository {
  /// جلب كل الطلاب
  Future<Either<Failure, List<StudentEntity>>> getAllStudents();

  /// مراقبة كل الطلاب (Stream)
  Stream<Either<Failure, List<StudentEntity>>> watchAllStudents();

  /// جلب طالب بالمعرف
  Future<Either<Failure, StudentEntity?>> getStudentById(int id);

  /// جلب طالب بالرقم
  Future<Either<Failure, StudentEntity?>> getStudentByCode(String studentCode);

  /// البحث عن طلاب
  Future<Either<Failure, List<StudentEntity>>> searchStudents(String query);

  /// إنشاء طالب
  Future<Either<Failure, int>> createStudent(StudentEntity student);

  /// تحديث طالب
  Future<Either<Failure, bool>> updateStudent(StudentEntity student);

  /// حذف طالب
  Future<Either<Failure, bool>> deleteStudent(int id);

  /// حذف كل الطلاب
  Future<Either<Failure, int>> deleteAllStudents();

  /// عدد الطلاب
  Future<Either<Failure, int>> getStudentsCount();
}
