import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:school_management_system/core/services/language_cubit.dart';
import 'package:school_management_system/core/services/translation_service.dart';
import 'package:school_management_system/core/theme/app_theme.dart';
import 'package:school_management_system/core/theme/theme_cubit.dart';
import 'package:school_management_system/core/utils/translation_extension.dart';
import 'package:school_management_system/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:school_management_system/features/auth/presentation/pages/login_page.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:school_management_system/features/grades/presentation/bloc/grades_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/homework/presentation/bloc/homework_bloc.dart';
import 'package:school_management_system/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:school_management_system/features/teachers/presentation/bloc/teachers_bloc.dart';
import 'package:school_management_system/injection_container.dart';

/// 📁 نقطة انطلاق التطبيق
///
/// ترتيب التهيئة مهم:
/// 1) تهيئة ارتباط Flutter مع النظام.
/// 2) تهيئة بيانات توطين التواريخ (وإلا يرمي `DateFormat` استثناءً بالعربية).
/// 3) تحميل ملف الترجمة الافتراضي.
/// 4) تسجيل التبعيات في حاوية الحقن.
/// 5) تشغيل الواجهة.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) توطين التواريخ — مطلوب قبل أي استخدام لـ DateFormat بلغة غير الإنجليزية
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');
  await initializeDateFormatting('fr');

  // 2) الترجمة الافتراضية
  await TranslationService.instance.loadTranslations('ar');

  // 3) حاوية الحقن
  await configureDependencies();

  // 4) التشغيل (مرة واحدة فقط)
  runApp(const SchoolManagementApp());
}

/// 📁 جذر التطبيق
class SchoolManagementApp extends StatelessWidget {
  const SchoolManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (BuildContext context, Widget? child) {
        return MultiBlocProvider(
          providers: [
            // --- إعدادات التطبيق ---
            BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
            BlocProvider<LanguageCubit>(create: (_) => LanguageCubit()),

            // --- حالات الميزات ---
            // ملاحظة: هذه الحالات متاحة للتطبيق كله. بعض الصفحات تُنشئ
            // نسخة خاصة بها (نمط قديم) — وسيُوحَّد ذلك في خطوة مستقلة.
            BlocProvider<StudentsBloc>(create: (_) => getIt<StudentsBloc>()),
            BlocProvider<SubjectsBloc>(create: (_) => getIt<SubjectsBloc>()),
            BlocProvider<TeachersBloc>(create: (_) => getIt<TeachersBloc>()),
            BlocProvider<EnrollmentBloc>(create: (_) => getIt<EnrollmentBloc>()),
            BlocProvider<GradesBloc>(create: (_) => getIt<GradesBloc>()),
            BlocProvider<GroupsBloc>(create: (_) => getIt<GroupsBloc>()),
            BlocProvider<FinanceBloc>(create: (_) => getIt<FinanceBloc>()),
            BlocProvider<AttendanceBloc>(
              create: (_) => getIt<AttendanceBloc>(),
            ),
            BlocProvider<NotificationBloc>(
              create: (_) => getIt<NotificationBloc>(),
            ),
            BlocProvider<HomeworkBloc>(create: (_) => getIt<HomeworkBloc>()),
          ],
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (BuildContext context, ThemeMode themeMode) {
              return BlocBuilder<LanguageCubit, Locale>(
                builder: (BuildContext context, Locale locale) {
                  return MaterialApp(
                    // النصوص تتبع ملفات الترجمة (لا نصوص مكتوبة في الكود)
                    onGenerateTitle: (BuildContext context) =>
                        context.tr('app.name'),
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeMode,
                    locale: locale,
                    // مصدر واحد للغات المدعومة
                    supportedLocales: LanguageCubit.supportedLocales,
                    localizationsDelegates:
                        const <LocalizationsDelegate<dynamic>>[
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
