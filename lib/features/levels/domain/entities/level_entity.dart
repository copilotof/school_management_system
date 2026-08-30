import 'package:equatable/equatable.dart';

class LevelEntity extends Equatable {
  final int? id;
  final String name;
  final int orderIndex;
  final bool isActive;
  final DateTime? createdAt;

  const LevelEntity({
    this.id,
    required this.name,
    this.orderIndex = 0,
    this.isActive = true,
    this.createdAt,
  });

  LevelEntity copyWith({
    int? id,
    String? name,
    int? orderIndex,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return LevelEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, orderIndex, isActive, createdAt];
}
