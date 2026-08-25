import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 📁 نظام الألوان والثيمات
/// يدعم الوضع الفاتح والداكن

// ================================================
// الألوان الأساسية (Light Mode)
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

  // ألوان مخصصة للنظام
  static const Color success = Color(0xFF34A853);
  static const Color warning = Color(0xFFF29900);
  static const Color info = Color(0xFF1A73E8);
  static const Color danger = Color(0xFFD93025);

  // ألوان الحضور
  static const Color present = Color(0xFF34A853);
  static const Color late = Color(0xFFF29900);
  static const Color excused = Color(0xFF1A73E8);
  static const Color unexcused = Color(0xFFD93025);

  // ألوان المالية
  static const Color paid = Color(0xFF34A853);
  static const Color partiallyPaid = Color(0xFFF29900);
  static const Color unpaid = Color(0xFFD93025);
  static const Color exempted = Color(0xFF1A73E8);
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

  // ألوان مخصصة
  static const Color success = Color(0xFF81C995);
  static const Color warning = Color(0xFFFDD663);
  static const Color info = Color(0xFF8AB4F8);
  static const Color danger = Color(0xFFF2B8B5);

  // ألوان الحضور
  static const Color present = Color(0xFF81C995);
  static const Color late = Color(0xFFFDD663);
  static const Color excused = Color(0xFF8AB4F8);
  static const Color unexcused = Color(0xFFF2B8B5);

  // ألوان المالية
  static const Color paid = Color(0xFF81C995);
  static const Color partiallyPaid = Color(0xFFFDD663);
  static const Color unpaid = Color(0xFFF2B8B5);
  static const Color exempted = Color(0xFF8AB4F8);
}

// ================================================
// نظام الثيم
// ================================================

class AppTheme {
  AppTheme._();

  /// الثيم الفاتح
  static ThemeData get lightTheme =>
      _buildTheme(brightness: Brightness.light, colors: _lightColorScheme);

  /// الثيم الداكن
  static ThemeData get darkTheme =>
      _buildTheme(brightness: Brightness.dark, colors: _darkColorScheme);

  /// نظام الألوان الفاتح
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
    background: AppLightColors.background,
    onBackground: AppLightColors.onBackground,
    surface: AppLightColors.surface,
    onSurface: AppLightColors.onSurface,
    surfaceVariant: AppLightColors.surfaceVariant,
    onSurfaceVariant: AppLightColors.onSurfaceVariant,
    outline: AppLightColors.outline,
    shadow: AppLightColors.shadow,
    scrim: AppLightColors.scrim,
  );

  /// نظام الألوان الداكن
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
    background: AppDarkColors.background,
    onBackground: AppDarkColors.onBackground,
    surface: AppDarkColors.surface,
    onSurface: AppDarkColors.onSurface,
    surfaceVariant: AppDarkColors.surfaceVariant,
    onSurfaceVariant: AppDarkColors.onSurfaceVariant,
    outline: AppDarkColors.outline,
    shadow: AppDarkColors.shadow,
    scrim: AppDarkColors.scrim,
  );

  /// بناء الثيم
  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colors,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: colors.onSurface,
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        color: colors.surface,
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: Size(double.infinity, 48.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: Size(double.infinity, 48.h),
          side: BorderSide(color: colors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: colors.surfaceVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: colors.surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        hintStyle: TextStyle(
          fontSize: 14.sp,
          color: colors.onSurfaceVariant.withOpacity(0.6),
        ),
        labelStyle: TextStyle(fontSize: 14.sp, color: colors.onSurfaceVariant),
        errorStyle: TextStyle(fontSize: 12.sp, color: colors.error),
        prefixIconColor: colors.onSurfaceVariant,
        suffixIconColor: colors.onSurfaceVariant,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colors.surfaceVariant,
        thickness: 1,
        space: 1,
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        backgroundColor: colors.onSurface,
        contentTextStyle: TextStyle(color: colors.surface, fontSize: 14.sp),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: colors.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14.sp,
          color: colors.onSurfaceVariant,
        ),
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        textColor: colors.onSurface,
        iconColor: colors.onSurfaceVariant,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(colors.primary),
        checkColor: WidgetStateProperty.all(colors.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(colors.primary),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(colors.primary),
        trackColor: WidgetStateProperty.all(colors.surfaceVariant),
      ),

      // ProgressIndicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceVariant,
        circularTrackColor: colors.surfaceVariant,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        labelStyle: TextStyle(fontSize: 12.sp, color: colors.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        side: BorderSide.none,
      ),
    );
  }
}
