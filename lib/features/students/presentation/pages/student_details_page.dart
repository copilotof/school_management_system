import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/utils/responsive.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/pages/edit_student_page.dart';

/// 📁 صفحة تفاصيل الطالب
/// تعرض كل معلومات الطالب مع العمر

class StudentDetailsPage extends StatelessWidget {
  final StudentEntity student;

  const StudentDetailsPage({super.key, required this.student});

  /// حساب العمر
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
        title: const Text('تفاصيل الطالب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل',
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditStudentPage(student: student),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.of(context).pop(true); // تحديث القائمة
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.smartPadding(mobile: 16, tablet: 24, desktop: 32),
          child: Column(
            children: [
              // ====== بطاقة المعلومات الأساسية ======
              Card(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      // الصورة / الحرف الأول
                      CircleAvatar(
                        radius: 50.r,
                        backgroundColor: colors.primary.withOpacity(0.1),
                        child: Text(
                          student.firstName.isNotEmpty
                              ? student.firstName.substring(0, 1)
                              : '؟',
                          style: TextStyle(
                            fontSize: 36.sp,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        student.fullName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'الرقم: ${student.studentCode}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // شارة الحالة
                      _StatusBadge(status: student.status),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // ====== بطاقة المعلومات الشخصية ======
              Card(
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.cake_outlined,
                      title: 'العمر',
                      value: age > 0 ? '$age سنة' : 'غير محدد',
                    ),
                    Divider(height: 1, color: colors.surfaceVariant),
                    _InfoTile(
                      icon: Icons.calendar_today,
                      title: 'تاريخ الميلاد',
                      value: student.dateOfBirth != null
                          ? DateFormat(
                              'yyyy/MM/dd',
                            ).format(student.dateOfBirth!)
                          : 'غير محدد',
                    ),
                    Divider(height: 1, color: colors.surfaceVariant),
                    _InfoTile(
                      icon: Icons.wc,
                      title: 'الجنس',
                      value: student.gender == 'male'
                          ? 'ذكر'
                          : student.gender == 'female'
                          ? 'أنثى'
                          : 'غير محدد',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // ====== بطاقة معلومات الاتصال ======
              Card(
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      title: 'الهاتف',
                      value: student.phone ?? 'غير محدد',
                    ),
                    Divider(height: 1, color: colors.surfaceVariant),
                    _InfoTile(
                      icon: Icons.location_on_outlined,
                      title: 'العنوان',
                      value: student.address ?? 'غير محدد',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // ====== بطاقة ملاحظات ======
              if (student.notes != null && student.notes!.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notes,
                              size: 20.sp,
                              color: colors.primary,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'ملاحظات',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          student.notes!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: colors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 📁 شارة الحالة
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'active' => (const Color(0xFF34A853), 'نشط'),
      'inactive' => (const Color(0xFFF29900), 'غير نشط'),
      'withdrawn' => (const Color(0xFFD93025), 'منسحب'),
      _ => (const Color(0xFF9AA0A6), 'غير معروف'),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// 📁 صف معلومات
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: colors.primary),
      title: Text(
        title,
        style: TextStyle(fontSize: 13.sp, color: colors.onSurfaceVariant),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
      ),
    );
  }
}
