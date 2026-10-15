import 'package:equatable/equatable.dart';

/// 📁 كيان الحصة

class SessionEntity extends Equatable {
  final int? id;
  final int groupId;
  final String? groupName;
  final int? templateId;
  final DateTime sessionDate;
  final DateTime startTime;
  final DateTime endTime;
  final String type; // regular, makeup, extra
  final String
  status; // scheduled, in_progress, completed, cancelled, postponed
  final String? lessonTopic;
  final String? teacherNotes;
  final String? homework;
  final String? cancelReason;
  final bool isPaid;
  final double? price;
  final String? paymentStatus; // unpaid, partial, paid, exempted
  final double paidAmount;
  final double remainingAmount;
  final int? studentsCount;
  final int? presentCount;
  final DateTime? createdAt;

  const SessionEntity({
    this.id,
    required this.groupId,
    this.groupName,
    this.templateId,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    this.type = 'regular',
    this.status = 'scheduled',
    this.lessonTopic,
    this.teacherNotes,
    this.homework,
    this.cancelReason,
    this.isPaid = false,
    this.price,
    this.paymentStatus,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.studentsCount,
    this.presentCount,
    this.createdAt,
  });

  /// ✅ مفتاح النوع — يُترجَم في الواجهة عبر `context.tr(...)`
  String get typeKey {
    switch (type) {
      case 'regular':
        return 'attendance.regular';
      case 'makeup':
        return 'attendance.makeup';
      case 'extra':
        return 'attendance.extra';
      default:
        return type;
    }
  }

  /// ✅ مفتاح الحالة — يُترجَم في الواجهة عبر `context.tr(...)`
  String get statusKey {
    switch (status) {
      case 'scheduled':
        return 'attendance.scheduled';
      case 'in_progress':
        return 'attendance.inProgress';
      case 'completed':
        return 'attendance.completed';
      case 'cancelled':
        return 'attendance.cancelled';
      case 'postponed':
        return 'attendance.postponed';
      default:
        return status;
    }
  }

  SessionEntity copyWith({
    int? id,
    int? groupId,
    String? groupName,
    int? templateId,
    DateTime? sessionDate,
    DateTime? startTime,
    DateTime? endTime,
    String? type,
    String? status,
    String? lessonTopic,
    String? teacherNotes,
    String? homework,
    String? cancelReason,
    bool? isPaid,
    double? price,
    String? paymentStatus,
    double? paidAmount,
    double? remainingAmount,
    int? studentsCount,
    int? presentCount,
    DateTime? createdAt,
  }) {
    return SessionEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      templateId: templateId ?? this.templateId,
      sessionDate: sessionDate ?? this.sessionDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      status: status ?? this.status,
      lessonTopic: lessonTopic ?? this.lessonTopic,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      homework: homework ?? this.homework,
      cancelReason: cancelReason ?? this.cancelReason,
      isPaid: isPaid ?? this.isPaid,
      price: price ?? this.price,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      studentsCount: studentsCount ?? this.studentsCount,
      presentCount: presentCount ?? this.presentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    groupName,
    templateId,
    sessionDate,
    startTime,
    endTime,
    type,
    status,
    lessonTopic,
    teacherNotes,
    homework,
    cancelReason,
    isPaid,
    price,
    paymentStatus,
    paidAmount,
    remainingAmount,
    studentsCount,
    presentCount,
    createdAt,
  ];
}
