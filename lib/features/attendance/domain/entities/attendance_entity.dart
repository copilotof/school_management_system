import 'package:equatable/equatable.dart';

/// 📁 كيان الحضور

class AttendanceEntity extends Equatable {
  final int? id;
  final int sessionId;
  final int studentId;
  final String? studentName;
  final String status; // present, absent, late فقط
  final DateTime? checkInTime;
  final int? recordedBy;
  final String? notes;
  final DateTime? createdAt;

  const AttendanceEntity({
    this.id,
    required this.sessionId,
    required this.studentId,
    this.studentName,
    required this.status,
    this.checkInTime,
    this.recordedBy,
    this.notes,
    this.createdAt,
  });

  String get statusLabel {
    switch (status) {
      case 'present':
        return 'حاضر';
      case 'absent':
        return 'غائب';
      case 'late':
        return 'متأخر';
      default:
        return status;
    }
  }

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isLate => status == 'late';

  @override
  List<Object?> get props => [
    id,
    sessionId,
    studentId,
    studentName,
    status,
    checkInTime,
    recordedBy,
    notes,
    createdAt,
  ];
}
