import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';

/// 📁 مصدر بيانات الإشعارات

class NotificationLocalDataSource {
  final AppDatabase db;

  NotificationLocalDataSource({required this.db});

  /// كل الإشعارات
  Future<List<Notification>> getAllNotifications() async {
    return await (db.select(db.notifications)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  /// إشعارات حسب المستلم
  Future<List<Notification>> getNotificationsByRecipient({
    required String recipientType,
    required int recipientId,
  }) async {
    return await (db.select(db.notifications)
          ..where(
            (t) =>
                t.recipientType.equals(recipientType) &
                (t.recipientId.equals(recipientId) | t.recipientId.isNull()),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// الإشعارات غير المقروءة
  Future<List<Notification>> getUnreadNotifications() async {
    return await (db.select(db.notifications)
          ..where((t) => t.isRead.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// عدد الإشعارات غير المقروءة
  Future<int> getUnreadCount() async {
    final count = db.notifications.id.count();
    final query = db.selectOnly(db.notifications)
      ..addColumns([count])
      ..where(db.notifications.isRead.equals(false));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// إضافة إشعار
  Future<int> createNotification(NotificationsCompanion notification) async {
    return await db.into(db.notifications).insert(notification);
  }

  /// تعليم إشعار كمقروء
  Future<bool> markAsRead(int id) async {
    final notification = await (db.select(
      db.notifications,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (notification == null) return false;

    final updated = notification.copyWith(isRead: true);
    await db.update(db.notifications).replace(updated);
    return true;
  }

  /// تعليم كل الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    await (db.update(db.notifications)..where((t) => t.isRead.equals(false)))
        .write(const NotificationsCompanion(isRead: Value(true)));
  }

  /// حذف إشعار
  Future<int> deleteNotification(int id) async {
    return await (db.delete(
      db.notifications,
    )..where((t) => t.id.equals(id))).go();
  }

  /// حذف كل الإشعارات
  Future<int> deleteAllNotifications() async {
    return await db.delete(db.notifications).go();
  }

  /// ✅ حذف إشعارات الدفع لطالب معين
  Future<int> deletePaymentNotificationsByStudent(int studentId) async {
    return await (db.delete(db.notifications)..where(
          (t) => t.type.equals('payment') & t.recipientId.equals(studentId),
        ))
        .go();
  }
}
