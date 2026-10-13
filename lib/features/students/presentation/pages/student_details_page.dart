import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/features/finance/presentation/pages/student_finance_page.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/pages/edit_student_page.dart';

import '../../../../core/utils/translation_extension.dart';
import '../../../attendance/presentation/pages/attendance_report_page.dart';
import '../../../enrollment/presentation/bloc/enrollment_bloc.dart';
import '../../../groups/presentation/bloc/groups_bloc.dart';
import '../../../groups/presentation/bloc/groups_state.dart';
import 'student_card_page.dart';

// ============================================================
// 🎨 ثوابت التصميم
// ============================================================
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 صفحة تفاصيل الطالب
class StudentDetailsPage extends StatelessWidget {
  final StudentEntity student;

  const StudentDetailsPage({super.key, required this.student});

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final age = _calculateAge(student.dateOfBirth);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('students.details')),
        actions: [
          IconButton(
            icon: Icon(Icons.badge_outlined, size: 20.sp),
            tooltip: context.tr('students.card'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudentCardPage(student: student),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.payments_outlined, size: 20.sp),
            tooltip: context.tr('finance.studentFinance'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudentFinancePage(student: student),
                ),
              );
            },
          ),

          // بعد أيقونة المالية
          BlocBuilder<EnrollmentBloc, EnrollmentState>(
            builder: (context, enrollmentState) {
              return BlocBuilder<GroupsBloc, GroupsState>(
                builder: (context, groupsState) {
                  final enrollments =
                      enrollmentState.enrollmentsState.data ?? [];
                  final groups = groupsState.groupsState.data ?? [];

                  // الأفواج المسجل فيها الطالب
                  final studentGroupIds = enrollments
                      .where(
                        (e) =>
                            e.studentId == student.id && e.status == 'active',
                      )
                      .map((e) => e.groupId)
                      .toSet();

                  final studentGroups = groups
                      .where((g) => studentGroupIds.contains(g.id))
                      .toList();

                  if (studentGroups.isEmpty) return const SizedBox.shrink();

                  return IconButton(
                    icon: const Icon(Icons.bar_chart, size: 20),
                    tooltip: context.tr('students.attendanceReport'),
                    onPressed: () {
                      if (studentGroups.length == 1) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AttendanceReportPage(
                              group: studentGroups.first,
                              student: student,
                            ),
                          ),
                        );
                      } else {
                        // اختيار الفوج
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('اختر الفوج'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: studentGroups
                                  .map(
                                    (g) => ListTile(
                                      title: Text(g.name),
                                      onTap: () {
                                        Navigator.of(dialogContext).pop();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AttendanceReportPage(
                                                  group: g,
                                                  student: student,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),

          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20.sp),
            tooltip: context.tr('common.edit'),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditStudentPage(student: student),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ====== بطاقة الطالب ======
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.primary.withOpacity(0.8)],
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
                    child: Text(
                      student.firstName.isNotEmpty
                          ? student.firstName.substring(0, 1)
                          : '؟',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: _Gap.md),
                  Text(
                    student.fullName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: _Gap.xs),
                  Text(
                    'الرقم: ${student.studentCode}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: _Gap.sm),
                  _StatusBadge(status: student.status),
                ],
              ),
            ),
            SizedBox(height: _Gap.md),

            // ====== المعلومات الشخصية ======
            _InfoCard(
              icon: Icons.person_outline,
              title: context.tr('students.personalInfo'),
              children: [
                _InfoRow(
                  icon: Icons.cake_outlined,
                  label: context.tr('students.age'),
                  value: age > 0
                      ? '$age ${context.tr('students.years')}'
                      : '-', // ✅
                ),
                Divider(height: 1, color: colors.surfaceVariant),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: context.tr('students.dateOfBirth'),
                  value: student.dateOfBirth != null
                      ? DateFormat('yyyy/MM/dd').format(student.dateOfBirth!)
                      : 'غير محدد',
                ),
                Divider(height: 1, color: colors.surfaceVariant),
                _InfoRow(
                  icon: Icons.wc,
                  label: context.tr('students.gender'),
                  value: student.gender == 'male'
                      ? context.tr('students.male')
                      : student.gender == 'female'
                      ? context.tr('students.female')
                      : context.tr('students.notSpecified'),
                ),
              ],
            ),
            SizedBox(height: _Gap.md),

            // ====== معلومات الاتصال ======
            _InfoCard(
              icon: Icons.phone_outlined,
              title: context.tr('students.contactInfo'),
              children: [
                _InfoRow(
                  icon: Icons.phone,
                  label: context.tr('students.phone'),
                  value: student.phone ?? context.tr('students.notSpecified'),
                ),
                Divider(height: 1, color: colors.surfaceVariant),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: context.tr('students.address'),
                  value: student.address ?? context.tr('students.notSpecified'),
                ),
              ],
            ),
            SizedBox(height: _Gap.md),

            // =====️ ملاحظات ======
            if (student.notes != null && student.notes!.isNotEmpty) ...[
              _InfoCard(
                icon: Icons.notes,
                title: context.tr('students.notes'),
                children: [
                  Text(
                    student.notes!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ],
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
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🏷️ شارة الحالة
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'active' => (const Color(0xFF34A853), context.tr('students.active')), // ✅
      'inactive' => (
        const Color(0xFFF29900),
        context.tr('students.inactive'),
      ), // ✅
      'withdrawn' => (
        const Color(0xFFD93025),
        context.tr('students.withdrawn'),
      ), // ✅
      _ => (const Color(0xFF9AA0A6), '?'),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
