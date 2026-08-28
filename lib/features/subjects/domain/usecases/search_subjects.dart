import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';
import 'package:school_management_system/features/subjects/domain/repositories/subject_repository.dart';

class SearchSubjects {
  final SubjectRepository repository;
  const SearchSubjects({required this.repository});

  Future<Either<Failure, List<SubjectEntity>>> call(String query) async {
    return await repository.searchSubjects(query);
  }
}
