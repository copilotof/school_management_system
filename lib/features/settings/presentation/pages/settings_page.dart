import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/services/language_cubit.dart';
import 'package:school_management_system/core/theme/theme_cubit.dart';
import 'package:school_management_system/core/utils/responsive.dart';
import 'package:school_management_system/core/utils/translation_extension.dart';

import '../../../../core/database/settings_local_source.dart';
import '../../../../injection_container.dart';
import '../../../grades/presentation/pages/grades_page.dart';
import '../../../levels/presentation/pages/levels_page.dart';
import '../../../notifications/presentation/pages/sms_log_page.dart';
import '../../../subjects/presentation/pages/subjects_page.dart';
import 'backup_page.dart';

/// 📁 صفحة الإعدادات
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _absenceLimit = 5; // ✅ حد الغيابات الافتراضي

  @override
  void initState() {
    super.initState();
    _loadAbsenceLimit();
  }

  Future<void> _loadAbsenceLimit() async {
    final settings = getIt<SettingsLocalDataSource>();
    final limit = await settings.getAbsenceLimit();
    if (mounted) {
      setState(() => _absenceLimit = limit);
    }
  }

  /* 
  Future<void> _showAbsenceLimitDialog(BuildContext context) async {
    final settings = getIt<SettingsLocalDataSource>();
    final currentLimit = await settings.getAbsenceLimit();
    final controller = TextEditingController(text: currentLimit.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حد الغيابات المسموح'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'عدد الغيابات',
            hintText: 'مثال: 5',
            prefixIcon: Icon(Icons.event_busy),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.of(dialogContext).pop(value);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result != null) {
      await settings.setAbsenceLimit(result);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تم حفظ الحد: $result غيابات')));
        setState(
          () => _absenceLimit = result,
        ); // إعادة البناء لعرض القيمة الجديدة
      }
    }
  }
    */
  Future<void> _showAbsenceLimitDialog(BuildContext context) async {
    final settings = getIt<SettingsLocalDataSource>();
    final currentLimit = await settings.getAbsenceLimit();

    if (!context.mounted) return;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) =>
          _AbsenceLimitDialog(currentLimit: currentLimit),
    );

    if (result != null) {
      await settings.setAbsenceLimit(result);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تم حفظ الحد: $result غيابات')));
        _loadAbsenceLimit();
      }
    }
  }

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

            // ====== قسم الإشعارات ======
            _SectionTitle(title: 'الإشعارات', colors: colors),
            SizedBox(height: 8.h),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.backup_outlined, color: colors.primary),
                    title: const Text('النسخ الاحتياطي'),
                    subtitle: const Text('نسخ واستعادة قاعدة البيانات'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BackupPage()),
                      );
                    },
                  ),
                  // ✅ جديد: سجل SMS
                  ListTile(
                    leading: Icon(Icons.sms_outlined, color: colors.primary),
                    title: const Text('سجل الرسائل القصيرة'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SmsLogPage()),
                      );
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.event_busy, color: colors.primary),
                    title: const Text('حد الغيابات المسموح'),
                    subtitle: Text('$_absenceLimit غيابات'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _showAbsenceLimitDialog(context),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

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
            SizedBox(height: 16.h),

            // ====== قسم المعلومات ======
            _SectionTitle(title: 'معلومات', colors: colors),
            SizedBox(height: 8.h),

            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('إصدار التطبيق'),
                    subtitle: Text('1.0.0'),
                  ),
                  Divider(height: 1, color: colors.surfaceVariant),
                  const ListTile(
                    leading: Icon(Icons.description_outlined),
                    title: Text('حول التطبيق'),
                    subtitle: Text('نظام إدارة المدارس التعليمية الخاصة'),
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

/// 📁 حوار تعديل حد الغيابات
class _AbsenceLimitDialog extends StatefulWidget {
  final int currentLimit;

  const _AbsenceLimitDialog({required this.currentLimit});

  @override
  State<_AbsenceLimitDialog> createState() => _AbsenceLimitDialogState();
}

class _AbsenceLimitDialogState extends State<_AbsenceLimitDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentLimit.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('حد الغيابات المسموح'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'عدد الغيابات',
          hintText: 'مثال: 5',
          prefixIcon: Icon(Icons.event_busy),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = int.tryParse(_controller.text);
            if (value != null && value > 0) {
              Navigator.of(context).pop(value);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('validators.invalidNumber'))),
              );
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
