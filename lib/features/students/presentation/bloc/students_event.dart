import 'package:equatable/equatable.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

/// 📁 أحداث الطلاب

abstract class StudentsEvent extends Equatable {
  const StudentsEvent();

  @override
  List<Object?> get props => [];
}

/// جلب كل الطلاب
class FetchStudents extends StudentsEvent {
  const FetchStudents();
}

/// البحث
class SearchStudentsEvent extends StudentsEvent {
  final String query;
  const SearchStudentsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// إنشاء
class CreateStudentEvent extends StudentsEvent {
  final StudentEntity student;
  const CreateStudentEvent(this.student);

  @override
  List<Object?> get props => [student];
}

/// تحديث
class UpdateStudentEvent extends StudentsEvent {
  final StudentEntity student;
  const UpdateStudentEvent(this.student);

  @override
  List<Object?> get props => [student];
}

/// حذف
class DeleteStudentEvent extends StudentsEvent {
  final int id;
  const DeleteStudentEvent(this.id);

  @override
  List<Object?> get props => [id];
}
