import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/enrollment/presentation/pages/enrollment_page.dart';
import 'package:school_management_system/features/groups/domain/entities/group_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';

import '../../../students/presentation/bloc/students_state.dart';

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
    });
  }

  Future<void> _openEnrollmentPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnrollmentPage(initialGroupId: widget.group.id),
      ),
    );
    // إعادة تحميل عند العودة
    if (mounted) {
      context.read<EnrollmentBloc>().add(FetchEnrollments());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====== بطاقة المعلومات ======
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 35.r,
                      backgroundColor: colors.secondary.withOpacity(0.1),
                      child: Icon(
                        Icons.groups,
                        size: 35.sp,
                        color: colors.secondary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      widget.group.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // ✅ معلومات مهمة في صفوف
                    _InfoRow(
                      icon: Icons.payments_outlined,
                      label: 'الرسوم الشهرية',
                      value: '${widget.group.monthlyFee.toStringAsFixed(0)} دج',
                      color: colors.primary,
                    ),
                    Divider(height: 16, color: colors.surfaceVariant),
                    _InfoRow(
                      icon: Icons.people_outline,
                      label: 'الطاقة الاستيعابية',
                      value: '${widget.group.maxStudents} طالب',
                      color: colors.secondary,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // ====== زر إدارة الطلاب ======
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openEnrollmentPage,
                icon: const Icon(Icons.person_add),
                label: const Text('إدارة الطلاب (إضافة/إلغاء)'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // ====== الطلاب المسجلون ======
            Text(
              'الطلاب المسجلون',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            SizedBox(height: 8.h),

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
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'لا يوجد طلاب مسجلون في هذا الفوج',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
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

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colors.primary.withOpacity(0.1),
                              child: Text(
                                student.firstName.isNotEmpty
                                    ? student.firstName.substring(0, 1)
                                    : '؟',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(student.fullName),
                            subtitle: Text('الرقم: ${student.studentCode}'),
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
    );
  }
}

/// 📁 صف معلومات
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20.sp, color: color),
        ),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(fontSize: 13.sp, color: colors.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}
