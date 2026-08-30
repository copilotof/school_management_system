import 'package:equatable/equatable.dart';

/// 📁 كيان الصف الدراسي

class GradeEntity extends Equatable {
  final int? id;
  final int? levelId; // المستوى المرتبط (اختياري)
  final String name;
  final int orderIndex;
  final bool isActive;
  final DateTime? createdAt;

  const GradeEntity({
    this.id,
    this.levelId,
    required this.name,
    this.orderIndex = 0,
    this.isActive = true,
    this.createdAt,
  });

  GradeEntity copyWith({
    int? id,
    int? levelId,
    String? name,
    int? orderIndex,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return GradeEntity(
      id: id ?? this.id,
      levelId: levelId ?? this.levelId,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    levelId,
    name,
    orderIndex,
    isActive,
    createdAt,
  ];
}
