import 'package:drift/drift.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/features/notifications/domain/entities/notification_entity.dart';

extension NotificationMapper on Notification {
  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      title: title,
      body: body,
      type: type,
      recipientType: recipientType,
      recipientId: recipientId,
      channel: channel,
      isRead: isRead,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  static NotificationsCompanion fromEntity(NotificationEntity entity) {
    return NotificationsCompanion.insert(
      title: entity.title,
      body: entity.body,
      type: entity.type,
      recipientType: entity.recipientType,
      recipientId: Value(entity.recipientId),
      channel: Value(entity.channel),
      isRead: Value(entity.isRead),
      metadata: Value(entity.metadata),
    );
  }
}
