import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/attendance/domain/entities/session_entity.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_entity.dart';
import 'package:school_management_system/features/homework/domain/entities/homework_submission_entity.dart';
import 'package:school_management_system/features/homework/presentation/bloc/homework_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';

import '../../../students/presentation/bloc/students_state.dart';

class _Gap {
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 نافذة عرض وتسجيل التسليمات
class HomeworkSubmissionsDialog extends StatelessWidget {
  final HomeworkEntity homework;
  final SessionEntity session;
  final HomeworkBloc homeworkBloc;

  const HomeworkSubmissionsDialog({
    super.key,
    required this.homework,
    required this.session,
    required this.homeworkBloc,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      insetPadding: EdgeInsets.all(16.w),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500.w,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ====== الرأس ======
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18.r,
                        backgroundColor: colors.tertiaryContainer,
                        child: Icon(
                          Icons.assignment,
                          size: 20.sp,
                          color: colors.onTertiaryContainer,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          homework.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  SizedBox(height: _Gap.sm),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          homework.description,
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12.sp,
                              color: colors.onSurfaceVariant,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'التسليم: ${DateFormat('yyyy/MM/dd').format(homework.dueDate)}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Icon(
                              Icons.category,
                              size: 12.sp,
                              color: colors.onSurfaceVariant,
                            ),
                            SizedBox(width: 4.w),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.outlineVariant),

            // ====== قائمة التسليمات ======
            Flexible(
              child: BlocBuilder<HomeworkBloc, HomeworkState>(
                bloc: homeworkBloc,
                builder: (context, state) {
                  return switch (state.submissionsState) {
                    Initial() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    Loading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    Empty() => const Center(child: Text('لا توجد تسليمات')),
                    Error(message: final msg) => Center(child: Text(msg)),
                    Success(data: final submissions) => _buildSubmissionsList(
                      context,
                      submissions,
                      homeworkBloc,
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsList(
    BuildContext context,
    List<HomeworkSubmissionEntity> submissions,
    HomeworkBloc homeworkBloc,
  ) {
    return BlocBuilder<StudentsBloc, StudentsState>(
      builder: (context, studentsState) {
        final students = studentsState.studentsState.data ?? [];

        if (submissions.isEmpty) {
          return const Center(child: Text('لا توجد تسليمات'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(12.w),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final submission = submissions[index];
            final student = students
                .where((s) => s.id == submission.studentId)
                .firstOrNull;
            if (student == null) return const SizedBox.shrink();

            return _SubmissionCard(
              submission: submission,
              studentName: student.fullName,
              studentCode: student.studentCode,
              onStatusChanged: (status) {
                final updated = submission.copyWith(
                  status: status,
                  submittedAt: status == 'submitted' || status == 'late'
                      ? DateTime.now()
                      : null,
                );
                homeworkBloc.add(UpdateSubmissionEvent(updated));
              },
            );
          },
        );
      },
    );
  }
}

/// 📁 بطاقة تسليم طالب
class _SubmissionCard extends StatelessWidget {
  final HomeworkSubmissionEntity submission;
  final String studentName;
  final String studentCode;
  final ValueChanged<String> onStatusChanged;

  const _SubmissionCard({
    required this.submission,
    required this.studentName,
    required this.studentCode,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final (statusColor, statusIcon, statusLabel) = switch (submission.status) {
      'submitted' => (colors.secondary, Icons.check_circle, 'سلّم'),
      'late' => (colors.primary, Icons.timelapse, 'متأخر'),
      'missing' => (colors.error, Icons.cancel, 'لم يسلّم'),
      _ => (colors.onSurfaceVariant, Icons.pending_outlined, 'معلّق'),
    };

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 6.h),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    studentName.isNotEmpty ? studentName.substring(0, 1) : '؟',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        studentCode,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(statusIcon, size: 16.sp, color: statusColor),
                SizedBox(width: 4.w),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // أزرار الحالة
            Row(
              children: [
                Expanded(
                  child: _StatusButton(
                    label: 'سلّم',
                    icon: Icons.check_circle,
                    color: colors.secondary,
                    isSelected: submission.status == 'submitted',
                    onTap: () => onStatusChanged('submitted'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _StatusButton(
                    label: 'متأخر',
                    icon: Icons.timelapse,
                    color: colors.primary,
                    isSelected: submission.status == 'late',
                    onTap: () => onStatusChanged('late'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _StatusButton(
                    label: 'لم يسلّم',
                    icon: Icons.cancel,
                    color: colors.error,
                    isSelected: submission.status == 'missing',
                    onTap: () => onStatusChanged('missing'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12.sp, color: isSelected ? Colors.white : color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
