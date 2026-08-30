import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/services/language_cubit.dart';
import 'package:school_management_system/core/theme/theme_cubit.dart';
import 'package:school_management_system/core/utils/responsive.dart';

import '../../../grades/presentation/pages/grades_page.dart';
import '../../../levels/presentation/pages/levels_page.dart';
import '../../../subjects/presentation/pages/subjects_page.dart';

/// 📁 صفحة الإعدادات

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: context.smartPadding(mobile: 16, tablet: 24, desktop: 32),
          children: [
            // ====== قسم المظهر ======
            _SectionTitle(title: 'المظهر', colors: colors),
            SizedBox(height: 8.h),

            // تبديل الثيم
            Card(
              child: ListTile(
                leading: Icon(Icons.dark_mode_outlined, color: colors.primary),
                title: const Text('الوضع الداكن'),
                trailing: BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, state) {
                    return Switch(
                      value: state == ThemeMode.dark,
                      onChanged: (_) {
                        context.read<ThemeCubit>().toggleTheme();
                      },
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // ====== قسم اللغة ======
            _SectionTitle(title: 'اللغة', colors: colors),
            SizedBox(height: 8.h),

            Card(
              child: BlocBuilder<LanguageCubit, Locale>(
                builder: (context, locale) {
                  return Column(
                    children: [
                      _LanguageTile(
                        title: 'العربية',
                        code: 'ar',
                        currentLocale: locale,
                        colors: colors,
                      ),
                      Divider(height: 1, color: colors.surfaceVariant),
                      _LanguageTile(
                        title: 'English',
                        code: 'en',
                        currentLocale: locale,
                        colors: colors,
                      ),
                      Divider(height: 1, color: colors.surfaceVariant),
                      _LanguageTile(
                        title: 'Français',
                        code: 'fr',
                        currentLocale: locale,
                        colors: colors,
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),

            // في ListView
            // ====== قسم الإدارة ======
            _SectionTitle(title: 'الإدارة', colors: colors),
            SizedBox(height: 8.h),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.class_outlined, color: colors.primary),
                    title: const Text('الصفوف الدراسية'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GradesPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.book_outlined, color: colors.primary),
                    title: const Text('المواد الدراسية'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SubjectsPage()),
                      );
                    },
                  ),
                  Divider(height: 1, color: colors.surfaceVariant),
                  ListTile(
                    leading: Icon(Icons.person_outline, color: colors.primary),
                    title: const Text('المعلمون'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      // سنضيف صفحة المعلمين لاحقاً
                    },
                  ),
                ],
              ),
            ),

            // ====== قسم المعلومات ======
            _SectionTitle(title: 'معلومات', colors: colors),
            SizedBox(height: 8.h),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline, color: colors.primary),
                    title: const Text('إصدار التطبيق'),
                    subtitle: const Text('1.0.0'),
                  ),
                  Divider(height: 1, color: colors.surfaceVariant),
                  ListTile(
                    leading: Icon(
                      Icons.description_outlined,
                      color: colors.primary,
                    ),
                    title: const Text('حول التطبيق'),
                    subtitle: const Text('نظام إدارة المدارس التعليمية الخاصة'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ====== قسم تسجيل الخروج ======
            Card(
              child: ListTile(
                leading: Icon(Icons.logout, color: colors.error),
                title: Text(
                  'تسجيل الخروج',
                  style: TextStyle(color: colors.error),
                ),
                onTap: () {
                  // العودة لصفحة تسجيل الدخول
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📁 عنوان قسم
class _SectionTitle extends StatelessWidget {
  final String title;
  final ColorScheme colors;
  const _SectionTitle({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: colors.primary,
      ),
    );
  }
}

/// 📁 خيار لغة
class _LanguageTile extends StatelessWidget {
  final String title;
  final String code;
  final Locale currentLocale;
  final ColorScheme colors;

  const _LanguageTile({
    required this.title,
    required this.code,
    required this.currentLocale,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentLocale.languageCode == code;

    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? colors.primary : colors.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colors.primary : colors.onSurface,
        ),
      ),
      onTap: () {
        context.read<LanguageCubit>().changeLocale(Locale(code));
      },
    );
  }
}
