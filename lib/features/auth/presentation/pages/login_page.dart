import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ⚠️ لا تحذف `hide DeviceType`: مكتبة screenutil تُعرّف `DeviceType` خاصة بها
// (mobile/tablet/web/mac/windows/linux/fuchsia) بينما `responsive.dart` تُعرّف
// `DeviceType` مختلفة. هذا الملف يستورد المكتبتين معًا، فبدون الإخفاء يحدث
// تعارض أسماء يمنع الترجمة.
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;
import 'package:school_management_system/core/services/language_cubit.dart';
import 'package:school_management_system/core/theme/theme_cubit.dart';
import 'package:school_management_system/core/utils/responsive.dart';
import 'package:school_management_system/core/utils/translation_extension.dart';
import 'package:school_management_system/features/home/presentation/pages/home_page.dart';
import 'package:school_management_system/features/notifications/services/auto_notification_service.dart';
import 'package:school_management_system/injection_container.dart';

/// 📁 صفحة تسجيل الدخول
///
/// - تصميم متجاوب (هاتف / تابلت / ديسكتوب)
/// - تبديل الثيم واللغة قبل الدخول
/// - فحص المتأخرات في الخلفية عند الدخول
///
/// ملاحظة: التحقق الفعلي من بيانات المستخدم لم يُنفَّذ بعد (يحتاج ميزة
/// المستخدمين والصلاحيات) — الدخول حاليًا ينتقل مباشرة إلى الصفحة الرئيسية.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// عرض النموذج الأقصى
  static const double _formMaxWidth = 400;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================
  // الدخول
  // ============================================

  void _handleLogin() {
    // فحص المتأخرات في الخلفية — لا ننتظره كي لا يتأخر الدخول
    unawaited(_checkOverdueInBackground());

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
    );
  }

  /// إنشاء إشعارات الدفع المتأخرة (يعمل في الخلفية)
  Future<void> _checkOverdueInBackground() async {
    try {
      final AutoNotificationService service = getIt<AutoNotificationService>();
      await service.checkPaymentOverdue();
    } catch (error) {
      assert(() {
        debugPrint('🔴 خطأ في فحص المتأخرات: $error');
        return true;
      }());
    }
  }

  // ============================================
  // البناء
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // ✅ تخطيط واحد يُبنى حسب نوع الجهاز (لا حاجة إلى LayoutBuilder)
        child: switch (context.deviceType) {
          DeviceType.mobile => _buildMobileLayout(context),
          DeviceType.tablet => _buildTabletLayout(context),
          DeviceType.desktop => _buildDesktopLayout(context),
        },
      ),
    );
  }

  /// 📱 تخطيط الهاتف
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _formMaxWidth),
          child: _buildLoginForm(context),
        ),
      ),
    );
  }

  /// 📟 تخطيط التابلت
  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(32.w),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: _buildLoginForm(context),
            ),
          ),
        ),
      ),
    );
  }

  /// 🖥️ تخطيط الديسكتوب
  Widget _buildDesktopLayout(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        // اللوحة الجانبية: الشعار
        Expanded(
          child: Container(
            color: colors.primary,
            padding: EdgeInsets.all(48.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.school, size: 80.sp, color: colors.onPrimary),
                SizedBox(height: 24.h),
                Text(
                  context.tr('app.name'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  context.tr('app.subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: colors.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),

        // النموذج
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(48.w),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _formMaxWidth),
                child: _buildLoginForm(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // نموذج الدخول
  // ============================================

  Widget _buildLoginForm(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isMobile = context.isMobile;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (isMobile) ...<Widget>[
          Icon(Icons.school, size: 64.sp, color: colors.primary),
          SizedBox(height: 16.h),
          Text(
            context.tr('app.name'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
        ] else ...<Widget>[
          Text(
            context.tr('auth.loginTitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
        ],
        SizedBox(height: 32.h),

        // البريد الإلكتروني
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.email],
          decoration: InputDecoration(
            labelText: context.tr('auth.email'),
            hintText: context.tr('auth.emailHint'),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        SizedBox(height: 16.h),

        // كلمة المرور
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.password],
          onSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            labelText: context.tr('auth.password'),
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

        ElevatedButton(
          onPressed: _handleLogin,
          child: Text(context.tr('auth.loginButton')),
        ),
        SizedBox(height: 16.h),

        _buildSettingsCard(context),
      ],
    );
  }

  // ============================================
  // بطاقة الإعدادات (الثيم + اللغة)
  // ============================================

  Widget _buildSettingsCard(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          children: <Widget>[
            // --- تبديل الثيم ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  context.tr('settings.darkMode'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (BuildContext context, ThemeMode mode) {
                    return Switch(
                      value: mode == ThemeMode.dark,
                      onChanged: (_) {
                        // ✅ من الوضع «حسب النظام» ينتقل إلى عكس وضع النظام
                        // الفعلي — بدل الانتقال إلى الداكن دائمًا (وهو ما كان
                        // يجعل الزر يبدو بلا أثر).
                        context.read<ThemeCubit>().toggleThemeFrom(context);
                      },
                    );
                  },
                ),
              ],
            ),

            Divider(height: 1, color: colors.surfaceContainerHighest),

            // --- اختيار اللغة ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  context.tr('settings.language'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                BlocBuilder<LanguageCubit, Locale>(
                  builder: (BuildContext context, Locale locale) {
                    return DropdownButton<Locale>(
                      value: locale,
                      underline: const SizedBox.shrink(),
                      items: <DropdownMenuItem<Locale>>[
                        // أسماء اللغات تبقى بلغتها الأصلية (وهي القيم نفسها
                        // المخزّنة في ملفات الترجمة، فلا ازدواج للنصوص).
                        DropdownMenuItem<Locale>(
                          value: const Locale('ar'),
                          child: Text(context.tr('settings.arabic')),
                        ),
                        DropdownMenuItem<Locale>(
                          value: const Locale('en'),
                          child: Text(context.tr('settings.english')),
                        ),
                        DropdownMenuItem<Locale>(
                          value: const Locale('fr'),
                          child: Text(context.tr('settings.french')),
                        ),
                      ],
                      onChanged: (Locale? newLocale) {
                        if (newLocale != null) {
                          context
                              .read<LanguageCubit>()
                              .changeLocale(newLocale);
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
    );
  }
}
