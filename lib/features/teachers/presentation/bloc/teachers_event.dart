import 'package:equatable/equatable.dart';
import 'package:school_management_system/features/teachers/domain/entities/teacher_entity.dart';

abstract class TeachersEvent extends Equatable {
  const TeachersEvent();

  @override
  List<Object?> get props => [];
}

class FetchTeachers extends TeachersEvent {
  const FetchTeachers();
}

class SearchTeachersEvent extends TeachersEvent {
  final String query;
  const SearchTeachersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class CreateTeacherEvent extends TeachersEvent {
  final TeacherEntity teacher;
  const CreateTeacherEvent(this.teacher);

  @override
  List<Object?> get props => [teacher];
}

class UpdateTeacherEvent extends TeachersEvent {
  final TeacherEntity teacher;
  const UpdateTeacherEvent(this.teacher);

  @override
  List<Object?> get props => [teacher];
}

class DeleteTeacherEvent extends TeachersEvent {
  final int id;
  const DeleteTeacherEvent(this.id);

  @override
  List<Object?> get props => [id];
}
