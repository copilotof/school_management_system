import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 📁 نظام الألوان والثيمات
/// يدعم الوضع الفاتح والداكن

// ================================================
// الألوان الفاتحة (Light Mode)
// ================================================
class AppLightColors {
  AppLightColors._();

  // الألوان الأساسية
  static const Color primary = Color(0xFF1A73E8);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD3E3FD);
  static const Color onPrimaryContainer = Color(0xFF041E49);

  static const Color secondary = Color(0xFF34A853);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFCEEAD6);
  static const Color onSecondaryContainer = Color(0xFF07281E);

  static const Color tertiary = Color(0xFFFBBC04);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFEF7E0);
  static const Color onTertiaryContainer = Color(0xFF3E2E04);

  static const Color error = Color(0xFFD93025);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF410E0B);

  // الخلفيات
  static const Color background = Color(0xFFF8F9FA);
  static const Color onBackground = Color(0xFF1F1F1F);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1F1F1F);
  static const Color surfaceVariant = Color(0xFFE8EAED);
  static const Color onSurfaceVariant = Color(0xFF444746);

  // عناصر إضافية
  static const Color outline = Color(0xFF747775);
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
}

// ================================================
// الألوان الداكنة (Dark Mode)
// ================================================
class AppDarkColors {
  AppDarkColors._();

  // الألوان الأساسية
  static const Color primary = Color(0xFF8AB4F8);
  static const Color onPrimary = Color(0xFF062E6F);
  static const Color primaryContainer = Color(0xFF0842A0);
  static const Color onPrimaryContainer = Color(0xFFD3E3FD);

  static const Color secondary = Color(0xFF81C995);
  static const Color onSecondary = Color(0xFF00391C);
  static const Color secondaryContainer = Color(0xFF00552A);
  static const Color onSecondaryContainer = Color(0xFFCEEAD6);

  static const Color tertiary = Color(0xFFFDD663);
  static const Color onTertiary = Color(0xFF3E2E04);
  static const Color tertiaryContainer = Color(0xFF5C4306);
  static const Color onTertiaryContainer = Color(0xFFFEF7E0);

  static const Color error = Color(0xFFF2B8B5);
  static const Color onError = Color(0xFF601410);
  static const Color errorContainer = Color(0xFF8C1D18);
  static const Color onErrorContainer = Color(0xFFF9DEDC);

  // الخلفيات
  static const Color background = Color(0xFF1F1F1F);
  static const Color onBackground = Color(0xFFE3E3E3);
  static const Color surface = Color(0xFF282A2D);
  static const Color onSurface = Color(0xFFE3E3E3);
  static const Color surfaceVariant = Color(0xFF3C4043);
  static const Color onSurfaceVariant = Color(0xFFC4C7C5);

  // عناصر إضافية
  static const Color outline = Color(0xFF8E918F);
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
}

// ================================================
// 📁 الألوان المخصّصة (Theme Extension)
// ================================================

/// ألوان النظام الخاصة التي لا وجود لها في `ColorScheme`:
/// حالات الحضور، حالات المالية، والحالات العامة.
///
/// **الاستخدام:**
/// ```dart
/// final custom = context.customColors;
/// Icon(Icons.check_circle, color: custom.present)
/// ```
///
/// ⚠️ لا تكتب هذه الألوان كنصوص سداسية داخل الشاشات — فهي لا تتكيّف
/// مع الوضع الداكن إن كُتبت مباشرة.
@immutable
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  const AppCustomColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.danger,
    required this.present,
    required this.late,
    required this.excused,
    required this.unexcused,
    required this.paid,
    required this.partiallyPaid,
    required this.unpaid,
    required this.exempted,
  });

  // الحالات العامة
  final Color success;
  final Color warning;
  final Color info;
  final Color danger;

  // ألوان الحضور
  final Color present;
  final Color late;
  final Color excused;
  final Color unexcused;

  // ألوان المالية
  final Color paid;
  final Color partiallyPaid;
  final Color unpaid;
  final Color exempted;

  /// الألوان في الوضع الفاتح
  static const AppCustomColors light = AppCustomColors(
    success: Color(0xFF34A853),
    warning: Color(0xFFF29900),
    info: Color(0xFF1A73E8),
    danger: Color(0xFFD93025),
    present: Color(0xFF34A853),
    late: Color(0xFFF29900),
    excused: Color(0xFF1A73E8),
    unexcused: Color(0xFFD93025),
    paid: Color(0xFF34A853),
    partiallyPaid: Color(0xFFF29900),
    unpaid: Color(0xFFD93025),
    exempted: Color(0xFF1A73E8),
  );

  /// الألوان في الوضع الداكن
  static const AppCustomColors dark = AppCustomColors(
    success: Color(0xFF81C995),
    warning: Color(0xFFFDD663),
    info: Color(0xFF8AB4F8),
    danger: Color(0xFFF2B8B5),
    present: Color(0xFF81C995),
    late: Color(0xFFFDD663),
    excused: Color(0xFF8AB4F8),
    unexcused: Color(0xFFF2B8B5),
    paid: Color(0xFF81C995),
    partiallyPaid: Color(0xFFFDD663),
    unpaid: Color(0xFFF2B8B5),
    exempted: Color(0xFF8AB4F8),
  );

  @override
  AppCustomColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? danger,
    Color? present,
    Color? late,
    Color? excused,
    Color? unexcused,
    Color? paid,
    Color? partiallyPaid,
    Color? unpaid,
    Color? exempted,
  }) {
    return AppCustomColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      danger: danger ?? this.danger,
      present: present ?? this.present,
      late: late ?? this.late,
      excused: excused ?? this.excused,
      unexcused: unexcused ?? this.unexcused,
      paid: paid ?? this.paid,
      partiallyPaid: partiallyPaid ?? this.partiallyPaid,
      unpaid: unpaid ?? this.unpaid,
      exempted: exempted ?? this.exempted,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      present: Color.lerp(present, other.present, t) ?? present,
      late: Color.lerp(late, other.late, t) ?? late,
      excused: Color.lerp(excused, other.excused, t) ?? excused,
      unexcused: Color.lerp(unexcused, other.unexcused, t) ?? unexcused,
      paid: Color.lerp(paid, other.paid, t) ?? paid,
      partiallyPaid:
          Color.lerp(partiallyPaid, other.partiallyPaid, t) ?? partiallyPaid,
      unpaid: Color.lerp(unpaid, other.unpaid, t) ?? unpaid,
      exempted: Color.lerp(exempted, other.exempted, t) ?? exempted,
    );
  }
}

/// 📁 وصول سريع للألوان المخصّصة من أي شاشة
extension AppColorsContext on BuildContext {
  /// الألوان المخصّصة (الحضور/المالية/الحالات)
  AppCustomColors get customColors {
    return Theme.of(this).extension<AppCustomColors>() ?? AppCustomColors.light;
  }

  /// هل الوضع الحالي داكن؟
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

// ================================================
// 📁 نظام الثيم
// ================================================

class AppTheme {
  AppTheme._();

  // ============================================
  // قيم موحّدة (Design Tokens)
  // ============================================
  static const double _radiusCard = 12;
  static const double _radiusSmall = 8;
  static const double _radiusLarge = 16;
  static const double _buttonHeight = 48;

  // ============================================
  // نظام الألوان الفاتح
  // ============================================
  static final ColorScheme _lightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: AppLightColors.primary,
    onPrimary: AppLightColors.onPrimary,
    primaryContainer: AppLightColors.primaryContainer,
    onPrimaryContainer: AppLightColors.onPrimaryContainer,
    secondary: AppLightColors.secondary,
    onSecondary: AppLightColors.onSecondary,
    secondaryContainer: AppLightColors.secondaryContainer,
    onSecondaryContainer: AppLightColors.onSecondaryContainer,
    tertiary: AppLightColors.tertiary,
    onTertiary: AppLightColors.onTertiary,
    tertiaryContainer: AppLightColors.tertiaryContainer,
    onTertiaryContainer: AppLightColors.onTertiaryContainer,
    error: AppLightColors.error,
    onError: AppLightColors.onError,
    errorContainer: AppLightColors.errorContainer,
    onErrorContainer: AppLightColors.onErrorContainer,
    surface: AppLightColors.surface,
    onSurface: AppLightColors.onSurface,
    // نضع اللون في الوسيطين: الحديث والمهجور، حتى لا يتغيّر أي موضع
    // يستخدم `colors.surfaceVariant` أثناء الترحيل التدريجي.
    surfaceContainerHighest: AppLightColors.surfaceVariant,
    surfaceVariant: AppLightColors.surfaceVariant,
    onSurfaceVariant: AppLightColors.onSurfaceVariant,
    outline: AppLightColors.outline,
    shadow: AppLightColors.shadow,
    scrim: AppLightColors.scrim,
  );

  // ============================================
  // نظام الألوان الداكن
  // ============================================
  static final ColorScheme _darkColorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: AppDarkColors.primary,
    onPrimary: AppDarkColors.onPrimary,
    primaryContainer: AppDarkColors.primaryContainer,
    onPrimaryContainer: AppDarkColors.onPrimaryContainer,
    secondary: AppDarkColors.secondary,
    onSecondary: AppDarkColors.onSecondary,
    secondaryContainer: AppDarkColors.secondaryContainer,
    onSecondaryContainer: AppDarkColors.onSecondaryContainer,
    tertiary: AppDarkColors.tertiary,
    onTertiary: AppDarkColors.onTertiary,
    tertiaryContainer: AppDarkColors.tertiaryContainer,
    onTertiaryContainer: AppDarkColors.onTertiaryContainer,
    error: AppDarkColors.error,
    onError: AppDarkColors.onError,
    errorContainer: AppDarkColors.errorContainer,
    onErrorContainer: AppDarkColors.onErrorContainer,
    surface: AppDarkColors.surface,
    onSurface: AppDarkColors.onSurface,
    surfaceContainerHighest: AppDarkColors.surfaceVariant,
    surfaceVariant: AppDarkColors.surfaceVariant,
    onSurfaceVariant: AppDarkColors.onSurfaceVariant,
    outline: AppDarkColors.outline,
    shadow: AppDarkColors.shadow,
    scrim: AppDarkColors.scrim,
  );

  /// الثيم الفاتح
  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        customColors: AppCustomColors.light,
      );

  /// الثيم الداكن
  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        colorScheme: _darkColorScheme,
        customColors: AppCustomColors.dark,
      );

  // ============================================
  // بناء الثيم
  // ============================================
  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required AppCustomColors customColors,
  }) {
    final bool isDark = brightness == Brightness.dark;

    // اللون الصريح للخلفية (بدل `colorScheme.background` المهجور)
    final Color background =
        isDark ? AppDarkColors.background : AppLightColors.background;
    final Color surfaceVariant = colorScheme.surfaceContainerHighest;

    return ThemeData(
      // ============= الأساسيات =============
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,

      // ============= AppBar =============
      appBarTheme: AppBarThemeData(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: isDark ? 0 : 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // ============= Card =============
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 2,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusCard.r),
        ),
      ),

      // ============= الأزرار =============
      // ملاحظة: نُبقي العرض الافتراضي ممتدًا (`double.infinity`) كما كان،
      // لأن توحيد مقاسات الأزرار يمسّ عشرات الشاشات ويجب أن يكون خطوة
      // مستقلة في مرحلة الواجهات.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor:
              colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor:
              colorScheme.onSurface.withValues(alpha: 0.38),
          minimumSize: Size(double.infinity, _buttonHeight.h),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSmall.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSmall.r),
          ),
          textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: Size(double.infinity, _buttonHeight.h),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSmall.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      // ============= حقول الإدخال =============
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: _inputBorder(surfaceVariant),
        enabledBorder: _inputBorder(surfaceVariant),
        focusedBorder: _inputBorder(colorScheme.primary, width: 2),
        errorBorder: _inputBorder(colorScheme.error),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: 2),
        hintStyle: TextStyle(
          fontSize: 14.sp,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        labelStyle: TextStyle(
          fontSize: 14.sp,
          color: colorScheme.onSurfaceVariant,
        ),
        errorStyle: TextStyle(fontSize: 12.sp, color: colorScheme.error),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),

      // ============= النصوص =============
      textTheme: _buildTextTheme(colorScheme),

      // ============= الفواصل =============
      dividerTheme: DividerThemeData(
        color: surfaceVariant,
        thickness: 1,
        space: 1,
      ),

      // ============= شريط التنقّل (Material 3) =============
      // المشروع يستخدم `NavigationBar` لا `BottomNavigationBar`، لذا هذا
      // هو الثيم الفعّال.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24.sp,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // ============= FloatingActionButton =============
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLarge.r),
        ),
      ),

      // ============= SnackBar =============
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? surfaceVariant : colorScheme.onSurface,
        contentTextStyle: TextStyle(
          fontSize: 14.sp,
          color: isDark ? colorScheme.onSurface : colorScheme.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSmall.r),
        ),
        elevation: 4,
        insetPadding: EdgeInsets.all(16.w),
      ),

      // ============= Dialog =============
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLarge.r),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14.sp,
          color: colorScheme.onSurfaceVariant,
        ),
        insetPadding: EdgeInsets.all(16.w),
      ),

      // ============= BottomSheet =============
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_radiusLarge.r),
          ),
        ),
        elevation: 8,
      ),

      // ============= ListTile =============
      listTileTheme: ListTileThemeData(
        textColor: colorScheme.onSurface,
        iconColor: colorScheme.onSurfaceVariant,
      ),

      // ============= Checkbox / Radio / Switch =============
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.outline;
        }),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.onPrimary
              : colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : surfaceVariant;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ============= ProgressIndicator =============
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: surfaceVariant,
        circularTrackColor: surfaceVariant,
      ),

      // ============= Chip =============
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: surfaceVariant.withValues(alpha: 0.5),
        labelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 12.sp,
          color: colorScheme.onPrimaryContainer,
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLarge.r),
        ),
        side: BorderSide.none,
        elevation: 0,
      ),

      // ============= Tooltip =============
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6.r),
        ),
        textStyle: TextStyle(fontSize: 12.sp, color: colorScheme.surface),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      ),

      // ============= الألوان المخصّصة =============
      extensions: <ThemeExtension<dynamic>>[customColors],
    );
  }

  // ============================================
  // حدود موحّدة لحقول الإدخال
  // ============================================
  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radiusSmall.r),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // ============================================
  // Text Theme
  // ============================================
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final Color onSurface = colorScheme.onSurface;
    final Color onSurfaceVariant = colorScheme.onSurfaceVariant;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.bold,
        color: onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.bold,
        color: onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        color: onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.bold,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 15.sp, color: onSurface),
      bodyMedium: TextStyle(fontSize: 14.sp, color: onSurface),
      bodySmall: TextStyle(fontSize: 12.sp, color: onSurfaceVariant),
      labelLarge: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
      ),
    );
  }
}
