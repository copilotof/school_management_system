import 'package:equatable/equatable.dart';

/// 📁 كيان الإشعار

class NotificationEntity extends Equatable {
  final int? id;
  final String title;
  final String body;
  final String type; // attendance, payment, session, general
  final String recipientType; // student, guardian, teacher, all
  final int? recipientId;
  final String channel; // in_app, sms, email
  final bool isRead;
  final String? metadata;
  final DateTime? createdAt;

  const NotificationEntity({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.recipientType,
    this.recipientId,
    this.channel = 'in_app',
    this.isRead = false,
    this.metadata,
    this.createdAt,
  });

  /// ✅ مفتاح النوع — يُترجَم في الواجهة عبر `context.tr(...)`
  ///
  /// الكيان لا يملك `BuildContext`، فلا يكتب نصًا عربيًا مباشرًا؛
  /// والمفاتيح `notifications.type*` جاهزة في اللغات الثلاث.
  String get typeKey {
    switch (type) {
      case 'attendance':
        return 'notifications.typeAttendance';
      case 'payment':
        return 'notifications.typePayment';
      case 'session':
        return 'notifications.typeSession';
      case 'general':
        return 'notifications.typeGeneral';
      default:
        return type;
    }
  }

  NotificationEntity copyWith({
    int? id,
    String? title,
    String? body,
    String? type,
    String? recipientType,
    int? recipientId,
    String? channel,
    bool? isRead,
    String? metadata,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      recipientType: recipientType ?? this.recipientType,
      recipientId: recipientId ?? this.recipientId,
      channel: channel ?? this.channel,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    type,
    recipientType,
    recipientId,
    channel,
    isRead,
    metadata,
    createdAt,
  ];
}
