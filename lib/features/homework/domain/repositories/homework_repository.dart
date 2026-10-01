import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_entity.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_submission_entity.dart';

import '../../../attendance/domain/entities/session_entity.dart';

abstract class HomeworkRepository {
  // الواجبات
  Future<Either<Failure, List<HomeworkEntity>>> getAllHomeworks();
  Future<Either<Failure, List<HomeworkEntity>>> getHomeworksByGroup(
    int groupId,
  );
  Future<Either<Failure, List<HomeworkEntity>>> getHomeworksBySession(
    int sessionId,
  );
  Future<Either<Failure, HomeworkEntity?>> getHomeworkById(int id);
  Future<Either<Failure, int>> createHomework(HomeworkEntity homework);
  Future<Either<Failure, bool>> updateHomework(HomeworkEntity homework);
  Future<Either<Failure, bool>> deleteHomework(int id);

  // التسليمات
  Future<Either<Failure, List<HomeworkSubmissionEntity>>>
  getSubmissionsByHomework(int homeworkId);
  Future<Either<Failure, bool>> updateSubmission(
    HomeworkSubmissionEntity submission,
  );
  Future<Either<Failure, void>> createSubmissionsForGroup({
    required int homeworkId,
    required int groupId,
  });

  Future<Either<Failure, List<SessionEntity>>> getUpcomingSessions({
    required int groupId,
    required DateTime after,
  });

  Future<Either<Failure, List<HomeworkEntity>>>
  getHomeworksByGroupAndDateRange({
    required int groupId,
    required DateTime from,
    required DateTime to,
  });
}
