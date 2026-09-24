import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/utils/responsive.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/enrollment/presentation/pages/enrollment_page.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_event.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';
import 'package:school_management_system/features/subjects/presentation/pages/subjects_page.dart';
import 'package:school_management_system/features/teachers/presentation/pages/teachers_page.dart';

import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../groups/presentation/bloc/groups_state.dart';
import '../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../students/presentation/bloc/students_state.dart';

// ============================================================
// 🎨 ثوابت التصميم
// ============================================================
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 16;

/// 📁 صفحة لوحة التحكم - مبسطة ومركزة
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentsBloc>().add(const FetchStudents());
      context.read<GroupsBloc>().add(const FetchGroups());
      context.read<EnrollmentBloc>().add(FetchEnrollments());
      context.read<NotificationBloc>().add(FetchNotifications()); // ✅
    });

    return const DashboardView();
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 18) return 'مساء الخير';
    return 'مساء الخير';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        automaticallyImplyLeading: false,
        actions: [
          // ✅ زر الإشعارات مع Badge
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'الإشعارات',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsPage(),
                        ),
                      );
                    },
                  ),
                  // Badge
                  if (state.unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16.w,
                          minHeight: 16.h,
                        ),
                        child: Text(
                          state.unreadCount > 99
                              ? '99+'
                              : '${state.unreadCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ====== بطاقة الترحيب ======
              _WelcomeCard(greeting: _greeting()),
              SizedBox(height: _Gap.lg),

              // ====== الإحصائيات ======
              Text(
                'الإحصائيات',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: _Gap.sm),
              BlocBuilder<StudentsBloc, StudentsState>(
                builder: (context, studentsState) {
                  final studentsCount =
                      studentsState.studentsState.data?.length ?? 0;

                  return BlocBuilder<GroupsBloc, GroupsState>(
                    builder: (context, groupsState) {
                      final groupsCount =
                          groupsState.groupsState.data?.length ?? 0;

                      return Row(
                        children: [
                          _StatCard(
                            title: 'الطلاب',
                            value: '$studentsCount',
                            icon: Icons.people_alt_rounded,
                            color: const Color(0xFF1A73E8),
                          ),
                          SizedBox(width: 10.w),
                          _StatCard(
                            title: 'الأفواج',
                            value: '$groupsCount',
                            icon: Icons.groups_rounded,
                            color: const Color(0xFF34A853),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              SizedBox(height: _Gap.lg),

              // ====== أقسام سريعة ======
              Text(
                'أقسام سريعة',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: _Gap.sm),
              GridView.count(
                crossAxisCount: context.isMobile ? 2 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 1.4,
                children: [
                  _QuickActionCard(
                    title: 'تسجيل طالب',
                    icon: Icons.link_rounded,
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
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF1A73E8),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SubjectsPage()),
                      );
                    },
                  ),
                  _QuickActionCard(
                    title: 'الحضور',
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFFFBBC04),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AttendancePage(),
                        ),
                      );
                    },
                  ),

                  _QuickActionCard(
                    title: 'الإعدادات',
                    icon: Icons.settings_rounded,
                    color: const Color(0xFF9AA0A6),
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

/// 📁 بطاقة الترحيب - مبسطة
class _WelcomeCard extends StatelessWidget {
  final String greeting;
  const _WelcomeCard({required this.greeting});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withOpacity(0.8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school_rounded, size: 28.sp, color: Colors.white),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'نظام إدارة المدرسة',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${now.day}/${now.month}/${now.year}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 📁 بطاقة إحصائية - كبيرة ومركزة
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

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(_kRadius),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24.sp, color: color),
            SizedBox(height: 6.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: TextStyle(fontSize: 11.sp, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📁 بطاقة إجراء سريع - مبسطة
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

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(_kRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kRadius),
            border: Border.all(color: colors.outlineVariant.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22.sp, color: color),
              ),
              SizedBox(height: 6.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
