import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/subjects/data/models/subject_mapper.dart';
import 'package:school_management_system/features/subjects/data/sources/subject_local_source.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';
import 'package:school_management_system/features/subjects/domain/repositories/subject_repository.dart';

/// 📁 تنفيذ مستودع المواد

class SubjectRepositoryImpl implements SubjectRepository {
  final SubjectLocalDataSource localDataSource;

  SubjectRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<SubjectEntity>>> getAllSubjects() async {
    try {
      final rows = await localDataSource.getAllSubjects();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب المواد: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<SubjectEntity>>> watchAllSubjects() {
    return localDataSource
        .watchAllSubjects()
        .map((rows) {
          return Right<Failure, List<SubjectEntity>>(
            rows.map((r) => r.toEntity()).toList(),
          );
        })
        .handleError((e) {
          return Left<Failure, List<SubjectEntity>>(
            DatabaseFailure('فشل في مراقبة المواد: $e'),
          );
        });
  }

  @override
  Future<Either<Failure, SubjectEntity?>> getSubjectById(int id) async {
    try {
      final row = await localDataSource.getSubjectById(id);
      return Right(row?.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب المادة: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SubjectEntity>>> searchSubjects(
    String query,
  ) async {
    try {
      final rows = await localDataSource.searchSubjects(query);
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في البحث: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createSubject(SubjectEntity subject) async {
    try {
      final companion = SubjectMapper.fromEntity(subject);
      final id = await localDataSource.createSubject(companion);
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure('فشل في إنشاء المادة: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateSubject(SubjectEntity subject) async {
    try {
      final current = await localDataSource.getSubjectById(subject.id!);
      if (current == null) {
        return const Left(NotFoundFailure('المادة غير موجودة'));
      }
      final updated = current.copyWith(
        name: subject.name,
        code: Value(subject.code),
        description: Value(subject.description),
        isActive: subject.isActive,
      );
      final result = await localDataSource.updateSubject(updated);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure('فشل في تحديث المادة: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteSubject(int id) async {
    try {
      final result = await localDataSource.deleteSubject(id);
      return Right(result > 0);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حذف المادة: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getSubjectsCount() async {
    try {
      return Right(await localDataSource.getSubjectsCount());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب عدد المواد: $e'));
    }
  }
}
