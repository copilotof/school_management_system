import 'package:equatable/equatable.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';

abstract class SubjectsEvent extends Equatable {
  const SubjectsEvent();

  @override
  List<Object?> get props => [];
}

class FetchSubjects extends SubjectsEvent {
  const FetchSubjects();
}

class SearchSubjectsEvent extends SubjectsEvent {
  final String query;
  const SearchSubjectsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class CreateSubjectEvent extends SubjectsEvent {
  final SubjectEntity subject;
  const CreateSubjectEvent(this.subject);

  @override
  List<Object?> get props => [subject];
}

class UpdateSubjectEvent extends SubjectsEvent {
  final SubjectEntity subject;
  const UpdateSubjectEvent(this.subject);

  @override
  List<Object?> get props => [subject];
}

class DeleteSubjectEvent extends SubjectsEvent {
  final int id;
  const DeleteSubjectEvent(this.id);

  @override
  List<Object?> get props => [id];
}
