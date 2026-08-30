import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/levels/domain/entities/level_entity.dart';

abstract class LevelRepository {
  Future<Either<Failure, List<LevelEntity>>> getAllLevels();
  Future<Either<Failure, int>> createLevel(LevelEntity level);
  Future<Either<Failure, bool>> updateLevel(LevelEntity level);
  Future<Either<Failure, bool>> deleteLevel(int id);
}
