import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/utils/responsive.dart';
import 'package:school_management_system/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:school_management_system/features/finance/presentation/pages/finance_page.dart';
import 'package:school_management_system/features/groups/presentation/pages/groups_page.dart';
import 'package:school_management_system/features/settings/presentation/pages/settings_page.dart';
import 'package:school_management_system/features/students/presentation/pages/students_page.dart';

import '../../../notifications/presentation/bloc/notification_bloc.dart';

/// 📁 الصفحة الرئيسية مع نظام الملاحة
/// تستخدم NavigationBar (Material 3)

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationBloc>().add(FetchNotifications());
    });
  }

  // قائمة الصفحات
  static const List<Widget> _pages = [
    DashboardPage(),
    StudentsPage(),
    GroupsPage(),
    FinancePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withOpacity(0.15),
        height: context.isMobile ? 65.h : 75.h,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'لوحة التحكم',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'الطلاب',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'الأفواج',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'المالية',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
