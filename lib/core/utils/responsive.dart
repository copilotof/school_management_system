import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 📁 أدوات التصميم المتجاوب (Responsive Design)
/// تستخدم flutter_screenutil للتحجيم + LayoutBuilder لتغيير التخطيط

// ================================================
// أنواع الأجهزة
// ================================================

/// 📁 نوع الجهاز الحالي
enum DeviceType {
  mobile, // هاتف صغير (< 600)
  tablet, // تابلت (600 - 1024)
  desktop, // ديسكتوب (> 1024)
}

/// 📁 نقاط التوقف (Breakpoints)
class Breakpoints {
  Breakpoints._();

  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;

  // نقاط توقف إضافية للهواتف
  static const double mobileSmall = 360;
  static const double mobileMedium = 400;
  static const double mobileLarge = 480;
}

/// 📁 Extension على BuildContext
extension ResponsiveContext on BuildContext {
  /// الحصول على حجم الشاشة
  Size get screenSize => MediaQuery.of(this).size;

  /// عرض الشاشة
  double get screenWidth => screenSize.width;

  /// ارتفاع الشاشة
  double get screenHeight => screenSize.height;

  /// نوع الجهاز
  DeviceType get deviceType {
    if (screenWidth < Breakpoints.mobile) return DeviceType.mobile;
    if (screenWidth < Breakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// هل هو هاتف؟
  bool get isMobile => deviceType == DeviceType.mobile;

  /// هل هو تابلت؟
  bool get isTablet => deviceType == DeviceType.tablet;

  /// هل هو ديسكتوب؟
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// هل الشاشة صغيرة جداً؟
  bool get isSmallMobile => screenWidth < Breakpoints.mobileSmall;

  /// هل الشاشة كبيرة؟
  bool get isLargeMobile =>
      screenWidth >= Breakpoints.mobileLarge &&
      screenWidth < Breakpoints.mobile;

  /// الاتجاه (عمودي/أفقي)
  Orientation get orientation => MediaQuery.of(this).orientation;
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;

  /// المساحة الآمنة
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// هل لوحة المفاتيح مفتوحة؟
  bool get isKeyboardOpen => MediaQuery.of(this).viewInsets.bottom > 0;
}

/// 📁 Extension على BuildContext للحصول على أحجام ذكية
extension SmartSizing on BuildContext {
  /// عرض ذكي: يتكيف مع نوع الجهاز
  double smartWidth(
    double mobileValue, {
    double? tabletValue,
    double? desktopValue,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileValue.w;
      case DeviceType.tablet:
        return (tabletValue ?? mobileValue * 1.5).w;
      case DeviceType.desktop:
        return (desktopValue ?? mobileValue * 2).w;
    }
  }

  /// ارتفاع ذكي
  double smartHeight(
    double mobileValue, {
    double? tabletValue,
    double? desktopValue,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileValue.h;
      case DeviceType.tablet:
        return (tabletValue ?? mobileValue * 1.5).h;
      case DeviceType.desktop:
        return (desktopValue ?? mobileValue * 2).h;
    }
  }

  /// حجم خط ذكي
  double smartFontSize(
    double mobileValue, {
    double? tabletValue,
    double? desktopValue,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileValue.sp;
      case DeviceType.tablet:
        return (tabletValue ?? mobileValue * 1.3).sp;
      case DeviceType.desktop:
        return (desktopValue ?? mobileValue * 1.6).sp;
    }
  }

  /// Padding ذكي
  EdgeInsets smartPadding({
    double mobile = 16,
    double? tablet,
    double? desktop,
  }) {
    final value = switch (deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet ?? mobile * 1.5,
      DeviceType.desktop => desktop ?? mobile * 2,
    };
    return EdgeInsets.all(value.w);
  }

  /// Padding أفقي ذكي
  EdgeInsets smartHorizontalPadding({
    double mobile = 16,
    double? tablet,
    double? desktop,
  }) {
    final value = switch (deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet ?? mobile * 1.5,
      DeviceType.desktop => desktop ?? mobile * 2,
    };
    return EdgeInsets.symmetric(horizontal: value.w);
  }

  /// Padding عمودي ذكي
  EdgeInsets smartVerticalPadding({
    double mobile = 16,
    double? tablet,
    double? desktop,
  }) {
    final value = switch (deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet ?? mobile * 1.5,
      DeviceType.desktop => desktop ?? mobile * 2,
    };
    return EdgeInsets.symmetric(vertical: value.h);
  }
}

/// 📁 Widget مساعد لتغيير التخطيط حسب نوع الجهاز
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet ?? mobile,
      DeviceType.desktop => desktop ?? tablet ?? mobile,
    };
  }
}

/// 📁 Widget مساعد لعرض محتوى بعرض أقصى محدد (للديسكتوب)
class ConstrainedWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ConstrainedWidth({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
