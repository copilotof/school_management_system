import 'package:equatable/equatable.dart';

/// 📁 كيان تسليم الواجب
class HomeworkSubmissionEntity extends Equatable {
  final int? id;
  final int homeworkId;
  final int studentId;
  final String? studentName; // للعرض
  final String status; // pending, submitted, late, missing
  final DateTime? submittedAt;
  final String? notes;
  final DateTime? createdAt;

  const HomeworkSubmissionEntity({
    this.id,
    required this.homeworkId,
    required this.studentId,
    this.studentName,
    this.status = 'pending',
    this.submittedAt,
    this.notes,
    this.createdAt,
  });

  /// ✅ مفتاح الحالة — يُترجَم في الواجهة عبر `context.tr(...)`
  String get statusKey {
    switch (status) {
      case 'submitted':
        return 'homework.submitted';
      case 'late':
        return 'homework.late';
      case 'missing':
        return 'homework.missing';
      default:
        return 'homework.pending';
    }
  }

  bool get isSubmitted => status == 'submitted';
  bool get isLate => status == 'late';
  bool get isMissing => status == 'missing';
  bool get isPending => status == 'pending';

  HomeworkSubmissionEntity copyWith({
    int? id,
    int? homeworkId,
    int? studentId,
    String? studentName,
    String? status,
    DateTime? submittedAt,
    String? notes,
    DateTime? createdAt,
  }) {
    return HomeworkSubmissionEntity(
      id: id ?? this.id,
      homeworkId: homeworkId ?? this.homeworkId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    homeworkId,
    studentId,
    studentName,
    status,
    submittedAt,
    notes,
    createdAt,
  ];
}
