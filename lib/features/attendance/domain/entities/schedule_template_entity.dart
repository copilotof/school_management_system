import 'package:equatable/equatable.dart';

/// 📁 كيان القالب الأسبوعي

class ScheduleTemplateEntity extends Equatable {
  final int? id;
  final int groupId;
  final int dayOfWeek; // 0=الأحد، 1=الإثنين... 6=السبت
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final bool isActive;
  final DateTime? createdAt;

  const ScheduleTemplateEntity({
    this.id,
    required this.groupId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.location,
    this.isActive = true,
    this.createdAt,
  });

  /// ✅ مفتاح اليوم — يُترجَم في الواجهة عبر `context.tr(...)`
  ///
  /// الترتيب مطابق لـ`dayOfWeek`: 0=الأحد … 6=السبت
  String get dayKey {
    const keys = [
      'days.sunday',
      'days.monday',
      'days.tuesday',
      'days.wednesday',
      'days.thursday',
      'days.friday',
      'days.saturday',
    ];
    return keys[dayOfWeek % 7];
  }

  ScheduleTemplateEntity copyWith({
    int? id,
    int? groupId,
    int? dayOfWeek,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ScheduleTemplateEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    dayOfWeek,
    startTime,
    endTime,
    location,
    isActive,
    createdAt,
  ];
}
