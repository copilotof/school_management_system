import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/utils/responsive.dart';

import '../../../enrollment/presentation/pages/enrollment_page.dart';
import '../../../subjects/presentation/pages/subjects_page.dart';
import '../../../teachers/presentation/pages/teachers_page.dart';

/// 📁 صفحة لوحة التحكم
/// تعرض ملخصاً سريعاً لأهم المعلومات

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.smartPadding(mobile: 16, tablet: 24, desktop: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة الترحيب
              _WelcomeCard(colors: colors),
              SizedBox(height: 20.h),

              // الإحصائيات
              Text(
                'إحصائيات سريعة',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: colors.onBackground,
                ),
              ),
              SizedBox(height: 12.h),

              // شبكة الإحصائيات
              GridView.count(
                crossAxisCount: context.isMobile ? 2 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: context.isMobile
                    ? 1.1
                    : 1.3, // ✅ نسبة أكبر للمساحة الرأسية
                children: const [
                  _StatCard(
                    title: 'الطلاب',
                    value: '0',
                    icon: Icons.people,
                    color: Color(0xFF1A73E8),
                  ),
                  _StatCard(
                    title: 'الأفواج',
                    value: '0',
                    icon: Icons.groups,
                    color: Color(0xFF34A853),
                  ),
                  _StatCard(
                    title: 'الحصص اليوم',
                    value: '0',
                    icon: Icons.schedule,
                    color: Color(0xFFFBBC04),
                  ),
                  _StatCard(
                    title: 'المتأخرات',
                    value: '0 دج',
                    icon: Icons.warning,
                    color: Color(0xFFD93025),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // أقسام سريعة
              Text(
                'أقسام سريعة',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: colors.onBackground,
                ),
              ),
              SizedBox(height: 12.h),

              // أزرار التنقل السريع
              GridView.count(
                crossAxisCount: context.isMobile ? 2 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 1.5,
                children: [
                  _QuickActionCard(
                    title: 'إضافة طالب',
                    icon: Icons.person_add,
                    color: const Color(0xFF1A73E8),
                    onTap: () {
                      // التنقل لإضافة طالب
                    },
                  ),
                  _QuickActionCard(
                    title: 'تسجيل طالب',
                    icon: Icons.link,
                    color: const Color(0xFF34A853),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EnrollmentPage(),
                        ),
                      );
                    },
                  ),
                  _QuickActionCard(
                    title: 'المواد الدراسية',
                    icon: Icons.book_outlined,
                    color: const Color(0xFF34A853),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SubjectsPage()),
                      );
                    },
                  ),
                  _QuickActionCard(
                    title: 'تسجيل الحضور',
                    icon: Icons.check_circle,
                    color: const Color(0xFF34A853),
                    onTap: () {},
                  ),
                  _QuickActionCard(
                    title: 'تسجيل دفعة',
                    icon: Icons.payment,
                    color: const Color(0xFFFBBC04),
                    onTap: () {},
                  ),
                  _QuickActionCard(
                    title: 'المعلمون',
                    icon: Icons.person_outline,
                    color: const Color(0xFFF29900),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TeachersPage()),
                      );
                    },
                  ),
                  _QuickActionCard(
                    title: 'التقارير',
                    icon: Icons.bar_chart,
                    color: const Color(0xFFD93025),
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 📁 بطاقة الترحيب
class _WelcomeCard extends StatelessWidget {
  final ColorScheme colors;
  const _WelcomeCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withOpacity(0.8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.school, size: 40.sp, color: colors.onPrimary),
          SizedBox(height: 12.h),
          Text(
            'مرحباً بك في نظام إدارة المدارس',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: colors.onPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'اليوم: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: TextStyle(
              fontSize: 14.sp,
              color: colors.onPrimary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// 📁 بطاقة إحصائية - نسخة محسنة بدون overflow
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الأيقونة مع مرونة
            Flexible(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20.sp, color: color),
              ),
            ),
            SizedBox(height: 4.h),
            // القيمة مع مرونة
            Flexible(
              flex: 1,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 2.h),
            // العنوان مع مرونة
            Flexible(
              flex: 1,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📁 بطاقة إجراء سريع
class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28.sp, color: color),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
