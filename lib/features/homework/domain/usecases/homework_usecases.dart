import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_entity.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_submission_entity.dart';
import 'package:school_management_system/features/homework/domain/repositories/homework_repository.dart';

import '../../../attendance/domain/entities/session_entity.dart';

class GetAllHomeworks {
  final HomeworkRepository repository;
  const GetAllHomeworks({required this.repository});
  Future<Either<Failure, List<HomeworkEntity>>> call() =>
      repository.getAllHomeworks();
}

class GetHomeworksByGroup {
  final HomeworkRepository repository;
  const GetHomeworksByGroup({required this.repository});
  Future<Either<Failure, List<HomeworkEntity>>> call(int groupId) =>
      repository.getHomeworksByGroup(groupId);
}

class GetHomeworksBySession {
  final HomeworkRepository repository;
  const GetHomeworksBySession({required this.repository});
  Future<Either<Failure, List<HomeworkEntity>>> call(int sessionId) =>
      repository.getHomeworksBySession(sessionId);
}

class CreateHomework {
  final HomeworkRepository repository;
  const CreateHomework({required this.repository});
  Future<Either<Failure, int>> call(HomeworkEntity homework) =>
      repository.createHomework(homework);
}

class UpdateHomework {
  final HomeworkRepository repository;
  const UpdateHomework({required this.repository});
  Future<Either<Failure, bool>> call(HomeworkEntity homework) =>
      repository.updateHomework(homework);
}

class DeleteHomework {
  final HomeworkRepository repository;
  const DeleteHomework({required this.repository});
  Future<Either<Failure, bool>> call(int id) => repository.deleteHomework(id);
}

class GetSubmissionsByHomework {
  final HomeworkRepository repository;
  const GetSubmissionsByHomework({required this.repository});
  Future<Either<Failure, List<HomeworkSubmissionEntity>>> call(
    int homeworkId,
  ) => repository.getSubmissionsByHomework(homeworkId);
}

class UpdateSubmission {
  final HomeworkRepository repository;
  const UpdateSubmission({required this.repository});
  Future<Either<Failure, bool>> call(HomeworkSubmissionEntity submission) =>
      repository.updateSubmission(submission);
}

class GetUpcomingSessions {
  final HomeworkRepository repository;
  const GetUpcomingSessions({required this.repository});
  Future<Either<Failure, List<SessionEntity>>> call({
    required int groupId,
    required DateTime after,
  }) => repository.getUpcomingSessions(groupId: groupId, after: after);
}

class GetHomeworksByGroupAndDateRange {
  final HomeworkRepository repository;
  const GetHomeworksByGroupAndDateRange({required this.repository});
  Future<Either<Failure, List<HomeworkEntity>>> call({
    required int groupId,
    required DateTime from,
    required DateTime to,
  }) => repository.getHomeworksByGroupAndDateRange(
    groupId: groupId,
    from: from,
    to: to,
  );
}
