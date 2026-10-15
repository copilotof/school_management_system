import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ⚠️ لا تحذف `hide DeviceType`: مكتبة screenutil تُعرّف `DeviceType` خاصة بها
// بينما `responsive.dart` تُعرّف `DeviceType` مختلفة، وهذا الملف يستورد
// المكتبتين معًا — فبدون الإخفاء يحدث تعارض أسماء يمنع الترجمة.
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;
import 'package:school_management_system/core/utils/responsive.dart';
import 'package:school_management_system/core/utils/translation_extension.dart';
import 'package:school_management_system/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:school_management_system/features/finance/presentation/pages/finance_page.dart';
import 'package:school_management_system/features/groups/presentation/pages/groups_page.dart';
import 'package:school_management_system/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:school_management_system/features/settings/presentation/pages/settings_page.dart';
import 'package:school_management_system/features/students/presentation/pages/students_page.dart';

/// 📁 الصفحة الرئيسية مع نظام الملاحة
///
/// - **الهاتف/التابلت:** `NavigationBar` أسفل الشاشة
/// - **الديسكتوب:** `NavigationRail` جانبي
/// - **بناء كسول:** لا تُبنى صفحة التبويب إلا عند أول زيارة له، مع الحفاظ
///   على حالتها بعد ذلك — فيبقى بدء التشغيل خفيفًا بدل بناء 5 شاشات ثقيلة.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// التبويب الحالي
  int _currentIndex = 0;

  /// التبويبات التي زارها المستخدم (لوحة التحكم جاهزة دائمًا)
  final Set<int> _visited = <int>{0};

  /// صفحات التبويبات — كل مُنشئيها `const` فتبقى القائمة `const`
  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    StudentsPage(),
    GroupsPage(),
    FinancePage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // جلب الإشعارات مرة واحدة.
    // `read` لا يسجّل اشتراكًا، لذا استخدامه في initState آمن ولا يحتاج
    // تأجيلًا — على عكس ما كان يحدث سابقًا.
    context.read<NotificationBloc>().add(FetchNotifications());
  }

  /// عند اختيار تبويب من الشريط
  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _visited.add(index); // ← البناء الكسول
    });
  }

  /// عناصر التنقّل الموحّدة للشريطين
  List<_NavItem> _navItems(BuildContext context) {
    return <_NavItem>[
      _NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: context.tr('menu.dashboard'),
      ),
      _NavItem(
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        label: context.tr('menu.students'),
      ),
      _NavItem(
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups,
        label: context.tr('menu.groups'),
      ),
      _NavItem(
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments,
        label: context.tr('menu.finance'),
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: context.tr('menu.settings'),
      ),
    ];
  }

  /// 📚 محتوى التبويبات (يبني فقط ما زاره المستخدم)
  Widget _buildPages() {
    return IndexedStack(
      index: _currentIndex,
      children: List<Widget>.generate(
        _pages.length,
        (int index) =>
            _visited.contains(index) ? _pages[index] : const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ تخطيط واحد فقط يُبنى حسب نوع الجهاز
    return switch (context.deviceType) {
      DeviceType.desktop => _buildDesktopLayout(context),
      _ => _buildMobileLayout(context),
    };
  }

  // ============================================
  // تخطيط الهاتف/التابلت
  // ============================================
  Widget _buildMobileLayout(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<_NavItem> items = _navItems(context);

    return Scaffold(
      body: _buildPages(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withValues(alpha: 0.15),
        height: context.isTablet ? 75.h : 65.h,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: items.map((_NavItem item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  // ============================================
  // تخطيط الديسكتوب
  // ============================================
  Widget _buildDesktopLayout(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<_NavItem> items = _navItems(context);

    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            backgroundColor: colors.surface,
            indicatorColor: colors.primary.withValues(alpha: 0.15),
            labelType: NavigationRailLabelType.all,
            minWidth: 76.w,
            destinations: items.map((_NavItem item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildPages()),
        ],
      ),
    );
  }
}

/// 📁 عنصر تنقّل موحّد
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
