import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/core/services/translation_service.dart';
import 'package:school_management_system/features/notifications/data/models/notification_mapper.dart';
import 'package:school_management_system/features/notifications/data/sources/notification_local_source.dart';
import 'package:school_management_system/features/notifications/domain/entities/notification_entity.dart';
import 'package:school_management_system/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource localDataSource;

  NotificationRepositoryImpl({required this.localDataSource});

  /// ✅ رسالة فشل مترجَمة — المستودع بلا `BuildContext` فيستخدم خدمة الترجمة
  /// (دالة واحدة تمنع تكرار نفس البناء في 9 مواضع)
  DatabaseFailure _failure(String key, Object error) => DatabaseFailure(
    TranslationService.instance.tr(key, params: {'error': '$error'}),
  );

  @override
  Future<Either<Failure, List<NotificationEntity>>>
  getAllNotifications() async {
    try {
      final rows = await localDataSource.getAllNotifications();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(_failure('errors.fetchNotifications', e));
    }
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>>
  getUnreadNotifications() async {
    try {
      final rows = await localDataSource.getUnreadNotifications();
      return Right(rows.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Left(_failure('errors.fetchNotifications', e));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      return Right(await localDataSource.getUnreadCount());
    } catch (e) {
      return Left(_failure('errors.generic', e));
    }
  }

  @override
  Future<Either<Failure, int>> createNotification(
    NotificationEntity notification,
  ) async {
    try {
      final companion = NotificationMapper.fromEntity(notification);
      return Right(await localDataSource.createNotification(companion));
    } catch (e) {
      return Left(_failure('errors.createNotification', e));
    }
  }

  @override
  Future<Either<Failure, bool>> markAsRead(int id) async {
    try {
      return Right(await localDataSource.markAsRead(id));
    } catch (e) {
      return Left(_failure('errors.generic', e));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await localDataSource.markAllAsRead();
      return const Right(null);
    } catch (e) {
      return Left(_failure('errors.generic', e));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteNotification(int id) async {
    try {
      return Right(await localDataSource.deleteNotification(id) > 0);
    } catch (e) {
      return Left(_failure('errors.generic', e));
    }
  }

  @override
  Future<Either<Failure, int>> deleteAllNotifications() async {
    try {
      return Right(await localDataSource.deleteAllNotifications());
    } catch (e) {
      return Left(_failure('errors.generic', e));
    }
  }

  @override
  Future<Either<Failure, int>> deletePaymentNotificationsByStudent(
    int studentId,
  ) async {
    try {
      return Right(
        await localDataSource.deletePaymentNotificationsByStudent(studentId),
      );
    } catch (e) {
      return Left(_failure('errors.generic', e));
    }
  }
}
