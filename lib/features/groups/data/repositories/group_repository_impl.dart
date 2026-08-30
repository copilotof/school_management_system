import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/groups/data/models/group_mapper.dart';
import 'package:school_management_system/features/groups/data/sources/group_local_source.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/groups/domain/repositories/group_repository.dart';

/// 📁 تنفيذ مستودع الأفواج

class GroupRepositoryImpl implements GroupRepository {
  final GroupLocalDataSource localDataSource;

  GroupRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<GroupEntity>>> getAllGroups() async {
    try {
      final rows = await localDataSource.getAllGroups();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب الأفواج: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEntity?>> getGroupById(int id) async {
    try {
      final row = await localDataSource.getGroupById(id);
      return Right(row?.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب الفوج: $e'));
    }
  }

  @override
  Future<Either<Failure, List<GroupEntity>>> searchGroups(String query) async {
    try {
      final rows = await localDataSource.searchGroups(query);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في البحث: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createGroup(GroupEntity group) async {
    try {
      final companion = GroupMapper.fromEntity(group);
      final id = await localDataSource.createGroup(companion);
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure('فشل في إنشاء الفوج: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateGroup(GroupEntity group) async {
    try {
      final current = await localDataSource.getGroupById(group.id!);
      if (current == null) {
        return const Left(NotFoundFailure('الفوج غير موجود'));
      }
      final updated = current.copyWith(
        name: group.name,
        subjectId: Value(group.subjectId),
        teacherId: Value(group.teacherId),
        academicLevelId: Value(group.academicLevelId), // ✅
        gradeId: Value(group.gradeId),
        maxStudents: group.maxStudents,
        monthlyFee: group.monthlyFee,
        isActive: group.isActive,
      );
      final result = await localDataSource.updateGroup(updated);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure('فشل في تحديث الفوج: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteGroup(int id) async {
    try {
      final result = await localDataSource.deleteGroup(id);
      return Right(result > 0);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حذف الفوج: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getGroupsCount() async {
    try {
      return Right(await localDataSource.getGroupsCount());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب عدد الأفواج: $e'));
    }
  }
}
