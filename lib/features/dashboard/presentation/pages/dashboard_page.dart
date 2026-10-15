import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/theme/app_theme.dart';
import 'package:school_management_system/core/utils/responsive.dart';
import 'package:school_management_system/core/utils/translation_extension.dart';
import 'package:school_management_system/features/attendance/presentation/pages/attendance_page.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/enrollment/presentation/pages/enrollment_page.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_event.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_state.dart';
import 'package:school_management_system/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:school_management_system/features/notifications/presentation/pages/notifications_page.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_state.dart';
import 'package:school_management_system/features/subjects/presentation/pages/subjects_page.dart';

// ============================================================
// 🎨 ثوابت التصميم
// ============================================================
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

class _Radius {
  static double get card => 16.r;
  static double get badge => 10.r;
}

/// 📁 صفحة لوحة التحكم
///
/// ⚠️ إصلاح جوهري: كانت `addPostFrameCallback` تُستدعى داخل `build`، فتُطلق
/// 4 طلبات جلب بيانات **في كل إطار** → حلقة لا نهائية من الاستعلامات على
/// قاعدة البيانات. الآن تُنفَّذ **مرة واحدة** من `initState`.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // بعد أول إطار فقط — مرة واحدة في عمر الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  /// جلب بيانات لوحة التحكم مرة واحدة
  void _loadInitialData() {
    context.read<StudentsBloc>().add(const FetchStudents());
    context.read<GroupsBloc>().add(const FetchGroups());
    context.read<EnrollmentBloc>().add(FetchEnrollments());
    context.read<NotificationBloc>().add(FetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return const DashboardView();
  }
}

/// 📁 عرض لوحة التحكم
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  String _greeting(BuildContext context) {
    final int hour = DateTime.now().hour;
    return hour < 12
        ? context.tr('dashboard.greetingMorning')
        : context.tr('dashboard.greetingEvening');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('dashboard.title')),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          const _NotificationsButton(),
          SizedBox(width: 4.w),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ====== بطاقة الترحيب ======
              _WelcomeCard(greeting: _greeting(context)),
              SizedBox(height: _Gap.lg),

              // ====== الإحصائيات ======
              _SectionTitle(title: context.tr('dashboard.statistics')),
              SizedBox(height: _Gap.sm),
              const _StatisticsSection(),
              SizedBox(height: _Gap.lg),

              // ====== أقسام سريعة ======
              _SectionTitle(title: context.tr('dashboard.quickActions')),
              SizedBox(height: _Gap.sm),
              const _QuickActionsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================
// 📁 عنوان قسم
// ================================================
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
    );
  }
}

// ================================================
// 📁 زر الإشعارات مع شارة العدد
// ================================================
class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (BuildContext context, NotificationState state) {
        return Stack(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: context.tr('notifications.title'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsPage(),
                ),
              ),
            ),
            if (state.unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: _NotificationBadge(count: state.unreadCount),
              ),
          ],
        );
      },
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: colors.error,
        borderRadius: BorderRadius.circular(_Radius.badge),
      ),
      constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.h),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: colors.onError,
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ================================================
// 📁 قسم الإحصائيات
// ================================================
class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection();

  @override
  Widget build(BuildContext context) {
    final AppCustomColors custom = context.customColors;

    return BlocBuilder<StudentsBloc, StudentsState>(
      builder: (BuildContext context, StudentsState studentsState) {
        return BlocBuilder<GroupsBloc, GroupsState>(
          builder: (BuildContext context, GroupsState groupsState) {
            return Row(
              children: <Widget>[
                _StatCard(
                  title: context.tr('dashboard.studentsCount'),
                  value: '${studentsState.studentsState.itemsCount}',
                  icon: Icons.people_alt_rounded,
                  color: custom.info,
                ),
                SizedBox(width: 10.w),
                _StatCard(
                  title: context.tr('dashboard.groupsCount'),
                  value: '${groupsState.groupsState.itemsCount}',
                  icon: Icons.groups_rounded,
                  color: custom.success,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ================================================
// 📁 قسم الإجراءات السريعة
// ================================================
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final AppCustomColors custom = context.customColors;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return GridView.count(
      crossAxisCount: context.isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10.w,
      mainAxisSpacing: 10.h,
      childAspectRatio: 1.4,
      children: <Widget>[
        _QuickActionCard(
          title: context.tr('dashboard.enrollStudent'),
          icon: Icons.link_rounded,
          color: custom.success,
          onTap: () => _open(context, const EnrollmentPage()),
        ),
        _QuickActionCard(
          title: context.tr('dashboard.subjects'),
          icon: Icons.menu_book_rounded,
          color: custom.info,
          onTap: () => _open(context, const SubjectsPage()),
        ),
        _QuickActionCard(
          title: context.tr('dashboard.attendance'),
          icon: Icons.check_circle_outline_rounded,
          color: colors.tertiary,
          onTap: () => _open(context, const AttendancePage()),
        ),
        _QuickActionCard(
          title: context.tr('dashboard.settings'),
          icon: Icons.settings_rounded,
          color: colors.outline,
          onTap: () {},
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}

// ================================================
// 📁 بطاقة الترحيب
// ================================================
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            colors.primary,
            colors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(_Radius.card),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_rounded,
              size: 28.sp,
              color: colors.onPrimary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: colors.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  context.tr('app.name'),
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                // ✅ تاريخ مُوطَّن وآمن (لا ينهار إن لم تُهيّأ بيانات اللغة)
                Text(
                  context.formatDate(DateTime.now()),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: colors.onPrimary.withValues(alpha: 0.7),
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

// ================================================
// 📁 بطاقة إحصائية
// ================================================
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(_Radius.card),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: <Widget>[
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================
// 📁 بطاقة إجراء سريع
// ================================================
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(_Radius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_Radius.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_Radius.card),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22.sp, color: color),
              ),
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
