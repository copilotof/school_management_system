import 'package:fpdart/fpdart.dart';
import 'package:school_management_system/core/errors/failures.dart';
import 'package:school_management_system/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getAllNotifications();
  Future<Either<Failure, List<NotificationEntity>>> getUnreadNotifications();
  Future<Either<Failure, int>> getUnreadCount();
  Future<Either<Failure, int>> createNotification(
    NotificationEntity notification,
  );
  Future<Either<Failure, bool>> markAsRead(int id);
  Future<Either<Failure, void>> markAllAsRead();
  Future<Either<Failure, bool>> deleteNotification(int id);
  Future<Either<Failure, int>> deleteAllNotifications();
  Future<Either<Failure, int>> deletePaymentNotificationsByStudent(
    int studentId,
  );
}
