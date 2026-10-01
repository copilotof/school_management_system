/* import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/theme/app_theme.dart';
import 'package:school_management_system/core/theme/theme_cubit.dart';
import 'package:school_management_system/features/auth/presentation/pages/login_page.dart';
import 'package:school_management_system/features/students/presentation/pages/students_page.dart';
import 'package:school_management_system/injection_container.dart';

Future<void> main() async {
  // مهم: استدعاء ensureInitialized أولاً
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // الحفاظ على الـ splash screen
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // تهيئة التبعيات
  await configureDependencies();

  runApp(const SchoolManagementApp());
}

class SchoolManagementApp extends StatelessWidget {
  const SchoolManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) {
        return BlocProvider(
          create: (_) => ThemeCubit(),
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp(
                title: 'نظام إدارة المدارس',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,

                // ====== دعم RTL/LTR ======
                locale: const Locale('ar'), // اللغة الافتراضية: العربية
                supportedLocales: const [
                  Locale('ar'), // العربية
                  Locale('en'), // الإنجليزية
                  Locale('fr'), // الفرنسية
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                // ✅ تلقائياً يعكس الاتجاه حسب اللغة
                // ar → RTL
                // en/fr → LTR

              //  home: const SplashGate(),
              home: const LoginPage(),
              );
            },
          ),
        );
      },
    );
  }
}

/// 📁 شاشة البوابة - مطابقة تماماً للـ native splash
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // محاكاة التهيئة
      await Future.delayed(const Duration(seconds: 2));

      // إزالة الـ splash
      FlutterNativeSplash.remove();

      // الانتقال للشاشة الرئيسية
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    } catch (e) {
      FlutterNativeSplash.remove();
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // لون الخلفية مطابق تماماً للـ native splash
      backgroundColor: isDark
          ? const Color(0xFF1F1F1F)
          : const Color(0xFFF8F9FA),
      body: Center(
        child: Image.asset(
          // استخدام الصورة المناسبة حسب الوضع
          isDark
              ? 'assets/images/splash_logo_dark.png'
              : 'assets/images/splash_logo.png',
          width: 150,
          height: 150,
          errorBuilder: (context, error, stackTrace) {
            // إذا لم توجد الصورة، عرض أيقونة بديلة
            return Icon(
              Icons.school,
              size: 80,
              color: isDark ? Colors.white : const Color(0xFF1A73E8),
            );
          },
        ),
      ),
    );
  }
}
 */
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:school_management_system/core/services/language_cubit.dart';
import 'package:school_management_system/core/theme/app_theme.dart';
import 'package:school_management_system/core/theme/theme_cubit.dart';
import 'package:school_management_system/features/auth/presentation/pages/login_page.dart';
import 'package:school_management_system/features/grades/presentation/bloc/grades_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/levels/presentation/bloc/levels_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_bloc.dart';
import 'package:school_management_system/injection_container.dart';

import 'features/attendance/presentation/bloc/attendance_bloc.dart';
import 'features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'features/finance/presentation/bloc/finance_bloc.dart';
import 'features/homework/presentation/bloc/homework_bloc.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  /* 
  // ✅ حذف قاعدة البيانات القديمة (مؤقت - للتطوير فقط)
  try {
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = File('${dir.path}/school_management_db.sqlite');
    if (await dbFile.exists()) {
      await dbFile.delete();
      debugPrint('🗑️ تم حذف قاعدة البيانات القديمة');
    }
  } catch (e) {
    debugPrint('خطأ في حذف قاعدة البيانات: $e');
  }

 */
  await configureDependencies();
  runApp(const SchoolManagementApp());

  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const SchoolManagementApp());
}

class SchoolManagementApp extends StatelessWidget {
  const SchoolManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit()),
            BlocProvider(create: (_) => LanguageCubit()),
            // ✅ رفع كل الـ Blocs هنا ليكونوا متاحين في كل مكان
            BlocProvider(create: (_) => getIt<StudentsBloc>()),
            BlocProvider(create: (_) => getIt<SubjectsBloc>()),
            BlocProvider(create: (_) => getIt<TeachersBloc>()),
            BlocProvider(create: (_) => getIt<EnrollmentBloc>()),
            BlocProvider(create: (_) => getIt<GradesBloc>()),
            BlocProvider(create: (_) => getIt<GroupsBloc>()),
            BlocProvider(create: (_) => getIt<FinanceBloc>()),
            BlocProvider(create: (_) => getIt<AttendanceBloc>()),
            BlocProvider(create: (_) => getIt<NotificationBloc>()),
            BlocProvider(create: (_) => getIt<HomeworkBloc>()),
          ],
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return BlocBuilder<LanguageCubit, Locale>(
                builder: (context, locale) {
                  return MaterialApp(
                    title: 'نظام إدارة المدارس',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeMode,
                    locale: locale,
                    supportedLocales: const [
                      Locale('ar'),
                      Locale('en'),
                      Locale('fr'),
                    ],
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    home: const LoginPage(),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
