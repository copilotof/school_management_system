import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 📁 أدوات التصميم المتجاوب (Responsive Design)
///
/// تجمع بين `flutter_screenutil` للتحجيم و`MediaQuery` الذكي لتغيير التخطيط.
///
/// **نقطة أداء مهمة:** نستخدم `MediaQuery.sizeOf/paddingOf/viewInsetsOf/
/// orientationOf` بدل `MediaQuery.of(context).xxx` — لأن `MediaQuery.of`
/// يجعل الودجة تُعاد بناؤها عند **أي** تغيير في MediaQuery (ومنها فتح
/// لوحة المفاتيح!)، بينما الدوال المخصّصة تُعيد البناء عند تغيّر ذلك
/// الجانب وحده.
///
/// **أمثلة:**
/// ```dart
/// if (context.isMobile) { ... }
/// Padding(padding: context.smartPadding(mobile: 16, tablet: 24), child: ...)
/// ResponsiveLayout(mobile: MobileView(), desktop: DesktopView())
/// GridView.count(crossAxisCount: context.gridColumns)
/// ```

// ================================================
// 📁 أنواع الأجهزة
// ================================================

/// نوع الجهاز الحالي
enum DeviceType {
  /// هاتف (< 600 بكسل)
  mobile,

  /// تابلت (600 - 1024 بكسل)
  tablet,

  /// ديسكتوب (> 1024 بكسل)
  desktop,
}

// ================================================
// 📁 نقاط التوقف (Breakpoints)
// ================================================

/// نقاط التوقف (Breakpoints) للتصميم المتجاوب
class Breakpoints {
  Breakpoints._();

  /// نهاية فئة الهاتف / بداية التابلت
  static const double mobile = 600;

  /// نهاية فئة التابلت / بداية الديسكتوب
  static const double tablet = 1024;

  /// عرض شاشة مرجعي للديسكتوب الكبير
  static const double desktop = 1440;

  // --- تصنيف أدق للهواتف ---

  /// هاتف صغير جدًا
  static const double mobileSmall = 360;

  /// هاتف متوسط
  static const double mobileMedium = 400;

  /// هاتف كبير
  static const double mobileLarge = 480;

  // --- فئات Material Design 3 ---

  /// نهاية `compact` / بداية `medium`
  static const double compactEnd = 600;

  /// نهاية `medium` / بداية `expanded`
  static const double mediumEnd = 840;
}

// ================================================
// 📁 Extension على BuildContext
// ================================================

extension ResponsiveContext on BuildContext {
  // --- حجم الشاشة ---

  /// حجم الشاشة
  Size get screenSize => MediaQuery.sizeOf(this);

  /// عرض الشاشة
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// ارتفاع الشاشة
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// نسبة العرض إلى الارتفاع
  double get aspectRatio => MediaQuery.sizeOf(this).aspectRatio;

  // --- نوع الجهاز ---

  /// نوع الجهاز الحالي
  DeviceType get deviceType {
    final double width = screenWidth;
    if (width < Breakpoints.mobile) return DeviceType.mobile;
    if (width < Breakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// هل هو هاتف؟
  bool get isMobile => deviceType == DeviceType.mobile;

  /// هل هو تابلت؟
  bool get isTablet => deviceType == DeviceType.tablet;

  /// هل هو ديسكتوب؟
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// هل الشاشة صغيرة جدًا؟
  bool get isSmallMobile => screenWidth < Breakpoints.mobileSmall;

  /// هل الشاشة كبيرة (داخل فئة الهاتف)؟
  bool get isLargeMobile =>
      screenWidth >= Breakpoints.mobileLarge &&
      screenWidth < Breakpoints.mobile;

  // --- الاتجاه ---

  /// الاتجاه الحالي (عمودي/أفقي)
  Orientation get orientation => MediaQuery.orientationOf(this);

  /// هل الشاشة عمودية؟
  bool get isPortrait => orientation == Orientation.portrait;

  /// هل الشاشة أفقية؟
  bool get isLandscape => orientation == Orientation.landscape;

  /// هل هو هاتف أفقي؟ (يحتاج معالجة خاصة للارتفاع)
  bool get isLandscapeMobile => isMobile && isLandscape;

  // --- المساحة والحدود ---

  /// المساحة الآمنة (للأجهزة ذات الشق/الحواف)
  EdgeInsets get safeAreaPadding => MediaQuery.paddingOf(this);

  /// ارتفاع لوحة المفاتيح
  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;

  /// هل لوحة المفاتيح مفتوحة؟
  bool get isKeyboardOpen => keyboardHeight > 0;

  /// الارتفاع المتاح فعلًا بعد خصم المساحة الآمنة ولوحة المفاتيح
  double get availableHeight =>
      screenHeight -
      safeAreaPadding.top -
      safeAreaPadding.bottom -
      keyboardHeight;

  // --- عدد أعمدة الشبكة ---

  /// عدد الأعمدة المقترح لـ `GridView` حسب نوع الجهاز
  int get gridColumns {
    return switch (deviceType) {
      DeviceType.mobile => 2,
      DeviceType.tablet => 3,
      DeviceType.desktop => 4,
    };
  }

  /// عدد الأعمدة حسب أقل عرض مقبول للعنصر
  int gridColumnsForItem(double minItemWidth, {double horizontalPadding = 32}) {
    final double available = screenWidth - horizontalPadding;
    final int columns = (available / minItemWidth).floor();
    return columns.clamp(1, 6);
  }

  // --- نسب سريعة ---

  /// نسبة من عرض الشاشة
  double widthPercent(double percent) => screenWidth * percent;

  /// نسبة من ارتفاع الشاشة
  double heightPercent(double percent) => screenHeight * percent;
}

// ================================================
// 📁 Extension للتحجيم الذكي
// ================================================

extension SmartSizing on BuildContext {
  /// عرض ذكي حسب نوع الجهاز
  double smartWidth(
    double mobileValue, {
    double? tabletValue,
    double? desktopValue,
  }) {
    return switch (deviceType) {
      DeviceType.mobile => mobileValue.w,
      DeviceType.tablet => (tabletValue ?? mobileValue * 1.5).w,
      DeviceType.desktop => (desktopValue ?? mobileValue * 2).w,
    };
  }

  /// ارتفاع ذكي حسب نوع الجهاز
  double smartHeight(
    double mobileValue, {
    double? tabletValue,
    double? desktopValue,
  }) {
    return switch (deviceType) {
      DeviceType.mobile => mobileValue.h,
      DeviceType.tablet => (tabletValue ?? mobileValue * 1.5).h,
      DeviceType.desktop => (desktopValue ?? mobileValue * 2).h,
    };
  }

  /// حجم خط ذكي حسب نوع الجهاز
  double smartFontSize(
    double mobileValue, {
    double? tabletValue,
    double? desktopValue,
  }) {
    return switch (deviceType) {
      DeviceType.mobile => mobileValue.sp,
      DeviceType.tablet => (tabletValue ?? mobileValue * 1.3).sp,
      DeviceType.desktop => (desktopValue ?? mobileValue * 1.6).sp,
    };
  }

  /// Padding ذكي (كل الاتجاهات)
  EdgeInsets smartPadding({
    double mobile = 16,
    double? tablet,
    double? desktop,
  }) {
    final double value = switch (deviceType) {
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
    final double value = switch (deviceType) {
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
    final double value = switch (deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet ?? mobile * 1.5,
      DeviceType.desktop => desktop ?? mobile * 2,
    };
    return EdgeInsets.symmetric(vertical: value.h);
  }

  /// مسافة بين العناصر (ذكية)
  double smartGap({
    double mobile = 8,
    double? tablet,
    double? desktop,
  }) {
    return switch (deviceType) {
      DeviceType.mobile => mobile.w,
      DeviceType.tablet => (tablet ?? mobile * 1.5).w,
      DeviceType.desktop => (desktop ?? mobile * 2).w,
    };
  }
}

// ================================================
// 📁 ودجات مساعدة
// ================================================

/// 📁 يختار التخطيط حسب نوع الجهاز
///
/// ملاحظة: الوسائط الثلاثة تُبنى ككائنات قبل الاختيار، لذا استخدمه فقط
/// عندما تكون التخطيطات خفيفة. للشاشات الثقيلة يُفضّل `switch` مباشر على
/// `context.deviceType` حتى يُبنى تخطيط واحد فقط.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet ?? mobile,
      DeviceType.desktop => desktop ?? tablet ?? mobile,
    };
  }
}

/// 📁 يقيّد عرض المحتوى (مفيد للديسكتوب والنماذج)
///
/// **مثال:** `ConstrainedWidth(maxWidth: 800, child: LoginForm())`
class ConstrainedWidth extends StatelessWidget {
  const ConstrainedWidth({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });

  final Widget child;
  final double maxWidth;

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
