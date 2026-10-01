import 'dart:convert';

import 'package:equatable/equatable.dart';

/// 📁 كيان الواجب
import 'package:equatable/equatable.dart';

/// 📁 كيان الواجب - مبسط
class HomeworkEntity extends Equatable {
  final int? id;
  final int sessionId; // الحصة التي أُعطي فيها
  final int? targetSessionId; // الحصة التي تُسلَّم فيها
  final int groupId;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final String? notes;
  final DateTime? createdAt;

  const HomeworkEntity({
    this.id,
    required this.sessionId,
    this.targetSessionId,
    required this.groupId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.notes,
    this.createdAt,
  });

  HomeworkEntity copyWith({
    int? id,
    int? sessionId,
    int? targetSessionId,
    int? groupId,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    String? notes,
    DateTime? createdAt,
  }) {
    return HomeworkEntity(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      targetSessionId: targetSessionId ?? this.targetSessionId,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sessionId,
    targetSessionId,
    groupId,
    title,
    description,
    dueDate,
    isCompleted,
    notes,
    createdAt,
  ];
}
