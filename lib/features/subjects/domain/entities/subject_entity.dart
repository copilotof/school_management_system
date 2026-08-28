import 'package:equatable/equatable.dart';

/// 📁 كيان المادة الدراسية

class SubjectEntity extends Equatable {
  final int? id;
  final String name;
  final String? code;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;

  const SubjectEntity({
    this.id,
    required this.name,
    this.code,
    this.description,
    this.isActive = true,
    this.createdAt,
  });

  SubjectEntity copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return SubjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, code, description, isActive, createdAt];
}
