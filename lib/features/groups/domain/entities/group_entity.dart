import 'package:equatable/equatable.dart';

/// 📁 كيان الفوج التربوي
/// الفوج = مادة + معلم + طلاب + رسوم

class GroupEntity extends Equatable {
  final int? id;
  final String name;
  final int? subjectId; // المادة
  final int? teacherId; // المعلم
  final int? academicLevelId; // ✅ المستوى
  final int? gradeId; // ✅ الصف
  final String? subjectName; // اسم المادة (للانضمام في العرض)
  final String? teacherName; // اسم المعلم (للانضمام في العرض)
  final int maxStudents; // الطاقة الاستيعابية
  final double monthlyFee; // الرسوم الشهرية
  final bool isActive;
  final DateTime? createdAt;

  const GroupEntity({
    this.id,
    required this.name,
    this.subjectId,
    this.teacherId,
    this.academicLevelId,
    this.gradeId,
    this.subjectName,
    this.teacherName,
    this.maxStudents = 30,
    this.monthlyFee = 0,
    this.isActive = true,
    this.createdAt,
  });

  GroupEntity copyWith({
    int? id,
    String? name,
    int? subjectId,
    int? teacherId,
    int? academicLevelId,
    int? gradeId,
    String? subjectName,
    String? teacherName,
    int? maxStudents,
    double? monthlyFee,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return GroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      subjectId: subjectId ?? this.subjectId,
      teacherId: teacherId ?? this.teacherId,
      academicLevelId: academicLevelId ?? this.academicLevelId,
      gradeId: gradeId ?? this.gradeId,
      subjectName: subjectName ?? this.subjectName,
      teacherName: teacherName ?? this.teacherName,
      maxStudents: maxStudents ?? this.maxStudents,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    subjectId,
    teacherId,
    academicLevelId,
    gradeId,
    subjectName,
    teacherName,
    maxStudents,
    monthlyFee,
    isActive,
    createdAt,
  ];
}
