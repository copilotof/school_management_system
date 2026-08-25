import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;
import 'package:school_management_system/core/theme/app_theme.dart';
import 'package:school_management_system/core/theme/theme_cubit.dart';
import 'package:school_management_system/core/utils/responsive.dart';

/// 📁 صفحة تسجيل الدخول - مثال عملي للتصميم المتجاوب

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // محاكاة تسجيل الدخول
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
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

  /// 📱 تخطيط الهاتف: عمودي بسيط
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: _buildLoginForm(context, maxWidth: 400),
    );
  }

  /// 📟 تخطيط التابلت: بطاقة مركزية
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

  /// 🖥️ تخطيط الديسكتوب: قسمين (شعار + نموذج)
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // القسم الأيسر: الشعار والمعلومات
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
                SizedBox(height: 12.h),
                Text(
                  'منصة متكاملة لإدارة المدارس التعليمية الخاصة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        // القسم الأيمن: النموذج
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

  /// 📝 نموذج تسجيل الدخول (مشترك بين جميع التخطيطات)
  Widget _buildLoginForm(BuildContext context, {required double maxWidth}) {
    final colors = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // العنوان
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

            // حقل البريد الإلكتروني
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                hintText: 'example@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال البريد الإلكتروني';
                }
                if (!value.contains('@')) {
                  return 'يرجى إدخال بريد إلكتروني صحيح';
                }
                return null;
              },
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال كلمة المرور';
                }
                if (value.length < 6) {
                  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                }
                return null;
              },
            ),
            SizedBox(height: 24.h),

            // زر تسجيل الدخول
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('تسجيل الدخول'),
            ),
            SizedBox(height: 16.h),

            // زر تبديل الثيم
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'الوضع الداكن',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 8.w),
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
          ],
        ),
      ),
    );
  }
}
