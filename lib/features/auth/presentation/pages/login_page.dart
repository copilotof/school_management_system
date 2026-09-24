import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;
import 'package:school_management_system/core/theme/app_theme.dart';
import 'package:school_management_system/core/theme/theme_cubit.dart';
import 'package:school_management_system/core/utils/responsive.dart';

import '../../../../core/services/language_cubit.dart';
import '../../../../injection_container.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../notifications/services/auto_notification_service.dart';
import '../../../students/presentation/pages/students_page.dart';

/// 📁 صفحة تسجيل الدخول - مثال عملي للتصميم المتجاوب

/// 📁 صفحة تسجيل الدخول - بدون تحقق (مؤقتاً)

/// 📁 صفحة تسجيل الدخول

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // ✅ فحص المتأخرات عند الدخول (بدون انتظار)
    _checkOverdueInBackground();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
  }

  /// ✅ فحص المتأخرات في الخلفية
  Future<void> _checkOverdueInBackground() async {
    try {
      final service = getIt<AutoNotificationService>();
      final count = await service.checkPaymentOverdue();
      debugPrint('🟢 تم إنشاء $count إشعار دفع عند الدخول');
    } catch (e) {
      debugPrint('🔴 خطأ في فحص المتأخرات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final deviceType = context.deviceType;
            return switch (deviceType) {
              DeviceType.mobile => _buildMobileLayout(context),
              DeviceType.tablet => _buildTabletLayout(context),
              DeviceType.desktop => _buildDesktopLayout(context),
            };
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: _buildLoginForm(context, maxWidth: 400),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(32.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 450),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: _buildLoginForm(context, maxWidth: 400),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: Theme.of(context).colorScheme.primary,
            padding: EdgeInsets.all(48.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school,
                  size: 80.sp,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                SizedBox(height: 24.h),
                Text(
                  'نظام إدارة المدارس',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(48.w),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildLoginForm(context, maxWidth: 400),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, {required double maxWidth}) {
    final colors = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (context.isMobile) ...[
            Icon(Icons.school, size: 64.sp, color: colors.primary),
            SizedBox(height: 16.h),
            Text(
              'نظام إدارة المدارس',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: colors.onBackground,
              ),
            ),
            SizedBox(height: 32.h),
          ] else ...[
            Text(
              'تسجيل الدخول',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: colors.onBackground,
              ),
            ),
            SizedBox(height: 32.h),
          ],

          // حقل البريد
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              hintText: 'example@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          SizedBox(height: 16.h),

          // حقل كلمة المرور
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // زر تسجيل الدخول
          ElevatedButton(
            onPressed: _handleLogin,
            child: const Text('تسجيل الدخول'),
          ),
          SizedBox(height: 16.h),

          // ====== أزرار الإعدادات (الثيم + اللغة) ======
          Card(
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                children: [
                  // تبديل الثيم
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الوضع الداكن',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      BlocBuilder<ThemeCubit, ThemeMode>(
                        builder: (context, state) {
                          return Switch(
                            value: state == ThemeMode.dark,
                            onChanged: (_) {
                              context.read<ThemeCubit>().toggleTheme();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  Divider(height: 1, color: colors.surfaceVariant),
                  // تغيير اللغة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'اللغة',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      BlocBuilder<LanguageCubit, Locale>(
                        builder: (context, locale) {
                          return DropdownButton<Locale>(
                            value: locale,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(
                                value: Locale('ar'),
                                child: Text('العربية'),
                              ),
                              DropdownMenuItem(
                                value: Locale('en'),
                                child: Text('English'),
                              ),
                              DropdownMenuItem(
                                value: Locale('fr'),
                                child: Text('Français'),
                              ),
                            ],
                            onChanged: (newLocale) {
                              if (newLocale != null) {
                                context.read<LanguageCubit>().changeLocale(
                                  newLocale,
                                );
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
