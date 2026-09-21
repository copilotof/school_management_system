import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/attendance/domain/entities/schedule_template_entity.dart';
import 'package:school_management_system/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:school_management_system/features/attendance/presentation/widgets/schedule_template_dialog.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/enrollment/presentation/pages/enrollment_page.dart';
import 'package:school_management_system/features/grades/domain/entities/grade_entity.dart';
import 'package:school_management_system/features/grades/presentation/bloc/grades_bloc.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_state.dart';
import 'package:school_management_system/features/subjects/domain/entities/subject_entity.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_event.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_state.dart';

// ثوابت التصميم
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

class GroupDetailsPage extends StatefulWidget {
  final GroupEntity group;

  const GroupDetailsPage({super.key, required this.group});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnrollmentBloc>().add(FetchEnrollments());
      context.read<StudentsBloc>().add(const FetchStudents());
      context.read<GradesBloc>().add(FetchGrades());
      context.read<SubjectsBloc>().add(const FetchSubjects());
      context.read<AttendanceBloc>().add(
        FetchTemplatesByGroup(widget.group.id!),
      );
    });
  }

  Future<void> _openEnrollmentPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnrollmentPage(initialGroupId: widget.group.id),
      ),
    );
    if (mounted) {
      context.read<EnrollmentBloc>().add(FetchEnrollments());
      setState(() {});
    }
  }

  int _getEnrolledStudentsCount(EnrollmentState state) {
    final enrollments = state.enrollmentsState.data ?? [];
    return enrollments
        .where((e) => e.groupId == widget.group.id && e.status == 'active')
        .length;
  }

  String _getGradeName(GradesState state) {
    if (widget.group.gradeId == null) return 'غير محدد';
    final grades = state.gradesState.data ?? [];
    final grade = grades.where((g) => g.id == widget.group.gradeId).firstOrNull;
    return grade?.name ?? 'غير محدد';
  }

  String _getSubjectName(SubjectsState state) {
    if (widget.group.subjectId == null) return 'غير محدد';
    final subjects = state.subjectsState.data ?? [];
    final subject = subjects
        .where((s) => s.id == widget.group.subjectId)
        .firstOrNull;
    return subject?.name ?? 'غير محدد';
  }

  /// ✅ نافذة إضافة/تعديل موعد أسبوعي
  void _showAddTemplateDialog(
    BuildContext context, {
    ScheduleTemplateEntity? template,
  }) {
    showDialog(
      context: context,
      builder: (_) => ScheduleTemplateDialog(
        groupId: widget.group.id!,
        template: template,
        onSubmit: (newTemplate) {
          if (template == null) {
            context.read<AttendanceBloc>().add(
              CreateTemplateEvent(newTemplate),
            );
          } else {
            context.read<AttendanceBloc>().add(
              UpdateTemplateEvent(newTemplate),
            );
          }
        },
      ),
    );
  }

  /// ✅ حذف موعد أسبوعي
  Future<void> _deleteTemplate(
    BuildContext context,
    ScheduleTemplateEntity template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف موعد ${template.dayLabel}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AttendanceBloc>().add(
        DeleteTemplateEvent(id: template.id!, groupId: widget.group.id!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ====== 1. بطاقة الفوج ======
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.secondary, colors.secondary.withOpacity(0.8)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(_kRadius),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40.r,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(Icons.groups, size: 36.sp, color: Colors.white),
                  ),
                  SizedBox(height: _Gap.md),
                  Text(
                    widget.group.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: _Gap.sm),
                  Text(
                    'الرسوم الشهرية: ${widget.group.monthlyFee.toStringAsFixed(0)} دج',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: _Gap.md),

            // ====== 2. معلومات الفوج ======
            BlocBuilder<EnrollmentBloc, EnrollmentState>(
              builder: (context, enrollmentState) {
                final studentsCount = _getEnrolledStudentsCount(
                  enrollmentState,
                );

                return BlocBuilder<GradesBloc, GradesState>(
                  builder: (context, gradesState) {
                    final gradeName = _getGradeName(gradesState);

                    return BlocBuilder<SubjectsBloc, SubjectsState>(
                      builder: (context, subjectsState) {
                        final subjectName = _getSubjectName(subjectsState);

                        return _InfoCard(
                          icon: Icons.info_outline,
                          title: 'معلومات الفوج',
                          children: [
                            _InfoRow(
                              icon: Icons.class_outlined,
                              label: 'الصف',
                              value: gradeName,
                            ),
                            Divider(height: 1, color: colors.surfaceVariant),
                            _InfoRow(
                              icon: Icons.book_outlined,
                              label: 'المادة',
                              value: subjectName,
                            ),
                            Divider(height: 1, color: colors.surfaceVariant),
                            _InfoRow(
                              icon: Icons.people_outline,
                              label: 'عدد الطلاب المسجلين',
                              value: '$studentsCount طالب',
                            ),
                            Divider(height: 1, color: colors.surfaceVariant),
                            _InfoRow(
                              icon: Icons.people_outline,
                              label: 'الطاقة الاستيعابية',
                              value: '${widget.group.maxStudents} طالب',
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            SizedBox(height: _Gap.lg),

            // ====== 3. ✅ الجدول الأسبوعي (هنا القسم الجديد) ======
            _InfoCard(
              icon: Icons.schedule,
              title: 'الجدول الأسبوعي',
              children: [
                BlocBuilder<AttendanceBloc, AttendanceState>(
                  builder: (context, state) {
                    return switch (state.templatesState) {
                      Initial() => const SizedBox.shrink(),
                      Loading() => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      Empty() => Column(
                        children: [
                          Text(
                            'لا توجد مواعيد أسبوعية',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          OutlinedButton.icon(
                            onPressed: () => _showAddTemplateDialog(context),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('إضافة موعد'),
                          ),
                        ],
                      ),
                      Error(message: final msg) => Text(
                        msg,
                        style: TextStyle(color: colors.error),
                      ),
                      Success(data: final templates) => Column(
                        children: [
                          ...templates.map(
                            (template) => _TemplateRow(
                              template: template,
                              onEdit: () => _showAddTemplateDialog(
                                context,
                                template: template,
                              ),
                              onDelete: () =>
                                  _deleteTemplate(context, template),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          OutlinedButton.icon(
                            onPressed: () => _showAddTemplateDialog(context),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('إضافة موعد'),
                          ),
                        ],
                      ),
                    };
                  },
                ),
              ],
            ),
            SizedBox(height: _Gap.lg),

            // ====== 4. الطلاب المسجلون ======
            Text(
              'الطلاب المسجلون',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: _Gap.sm),

            BlocBuilder<EnrollmentBloc, EnrollmentState>(
              builder: (context, enrollmentState) {
                final enrollments = enrollmentState.enrollmentsState.data ?? [];
                final groupEnrollments = enrollments
                    .where(
                      (e) =>
                          e.groupId == widget.group.id && e.status == 'active',
                    )
                    .toList();

                if (groupEnrollments.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(_kRadius),
                    ),
                    child: Text(
                      'لا يوجد طلاب مسجلون في هذا الفوج',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return BlocBuilder<StudentsBloc, StudentsState>(
                  builder: (context, studentsState) {
                    final students = studentsState.studentsState.data ?? [];

                    return Column(
                      children: groupEnrollments.map((enrollment) {
                        final student = students
                            .where((s) => s.id == enrollment.studentId)
                            .firstOrNull;

                        if (student == null) return const SizedBox.shrink();

                        final enrollmentDate = enrollment.enrollmentDate;

                        return Container(
                          margin: EdgeInsets.only(bottom: 6.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: colors.outlineVariant.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18.r,
                                backgroundColor: colors.primaryContainer,
                                child: Text(
                                  student.firstName.isNotEmpty
                                      ? student.firstName.substring(0, 1)
                                      : '؟',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: colors.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.fullName,
                                      style: TextStyle(
                                        fontSize: 13.5.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'الرقم: ${student.studentCode}',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12.sp,
                                    color: colors.secondary,
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    DateFormat(
                                      'yyyy/MM/dd',
                                    ).format(enrollmentDate),
                                    style: TextStyle(
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: colors.secondary,
                                    ),
                                  ),
                                  Text(
                                    'تاريخ الانضمام',
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      // ====== شريط سفلي ثابت ======
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 48.h,
            child: ElevatedButton.icon(
              onPressed: _openEnrollmentPage,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('إدارة الطلاب (إضافة/إلغاء)'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kRadius),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 📦 بطاقة معلومات
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: colors.primary),
              SizedBox(width: 6.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: _Gap.sm),
          ...children,
        ],
      ),
    );
  }
}

/// 📄 صف معلومات
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: colors.onSurfaceVariant),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: colors.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// 📅 صف القالب الأسبوعي
class _TemplateRow extends StatelessWidget {
  final ScheduleTemplateEntity template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateRow({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final startStr =
        '${template.startTime.hour.toString().padLeft(2, '0')}:${template.startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${template.endTime.hour.toString().padLeft(2, '0')}:${template.endTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              template.dayLabel,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '$startStr - $endStr',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 16.sp, color: colors.primary),
            onPressed: onEdit,
            tooltip: 'تعديل',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(width: 6.w),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 16.sp, color: colors.error),
            onPressed: onDelete,
            tooltip: 'حذف',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
