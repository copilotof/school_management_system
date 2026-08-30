import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/levels/data/models/level_mapper.dart';
import 'package:school_management_system/features/levels/data/sources/level_local_source.dart';
import 'package:school_management_system/features/levels/domain/entities/level_entity.dart';
import 'package:school_management_system/features/levels/domain/repositories/level_repository.dart';

class LevelRepositoryImpl implements LevelRepository {
  final LevelLocalDataSource localDataSource;

  LevelRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<LevelEntity>>> getAllLevels() async {
    try {
      final rows = await localDataSource.getAllLevels();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب المستويات: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createLevel(LevelEntity level) async {
    try {
      final companion = LevelMapper.fromEntity(level);
      return Right(await localDataSource.createLevel(companion));
    } catch (e) {
      return Left(DatabaseFailure('فشل في إنشاء المستوى: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateLevel(LevelEntity level) async {
    try {
      final current = await localDataSource.getAllLevels();
      final row = current.where((r) => r.id == level.id).firstOrNull;
      if (row == null) return const Left(NotFoundFailure('المستوى غير موجود'));
      final updated = row.copyWith(
        name: level.name,
        orderIndex: level.orderIndex,
        isActive: level.isActive,
      );
      return Right(await localDataSource.updateLevel(updated));
    } catch (e) {
      return Left(DatabaseFailure('فشل في تحديث المستوى: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteLevel(int id) async {
    try {
      return Right(await localDataSource.deleteLevel(id) > 0);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حذف المستوى: $e'));
    }
  }
}
