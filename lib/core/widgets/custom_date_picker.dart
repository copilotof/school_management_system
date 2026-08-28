import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

/// 📁 مكوّن اختيار التاريخ المخصص
/// يستخدم Syncfusion DatePicker
/// - خلفية بيضاء ونص أسود
/// - يبدأ بعرض السنوات أولاً

class CustomDatePicker {
  /// إظهار حوار اختيار التاريخ
  static Future<DateTime?> show({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
  }) async {
    final now = DateTime.now();
    final selectedDate = initialDate ?? DateTime(now.year - 10, 1, 1);

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: BoxConstraints(maxWidth: 400.w, maxHeight: 520.h),
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // العنوان
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'اختر التاريخ',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                const Divider(color: Colors.black12),
                SizedBox(height: 8.h),

                // تقويم Syncfusion
                Flexible(
                  child: SfDateRangePicker(
                    initialSelectedDate: selectedDate,
                    minDate: minDate ?? DateTime(now.year - 50),
                    maxDate: maxDate ?? DateTime(now.year + 1),
                    showActionButtons: false,
                    showNavigationArrow: true,
                    selectionMode: DateRangePickerSelectionMode.single,

                    // ✅ يبدأ بعرض السنوات
                    view: DateRangePickerView.decade,

                    // ====== تخصيص الألوان ======
                    backgroundColor: Colors.white,
                    headerStyle: const DateRangePickerHeaderStyle(
                      backgroundColor: Colors.white,
                      textStyle: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    monthViewSettings: const DateRangePickerMonthViewSettings(
                      firstDayOfWeek: 6,
                      dayFormat: 'EEE',
                      viewHeaderStyle: DateRangePickerViewHeaderStyle(
                        backgroundColor: Colors.white,
                        textStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    yearCellStyle: const DateRangePickerYearCellStyle(
                      textStyle: TextStyle(color: Colors.black87, fontSize: 14),
                      todayTextStyle: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      leadingDatesTextStyle: TextStyle(color: Colors.black38),
                    ),
                    monthCellStyle: const DateRangePickerMonthCellStyle(
                      textStyle: TextStyle(color: Colors.black87, fontSize: 14),
                      todayTextStyle: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      leadingDatesTextStyle: TextStyle(color: Colors.black38),
                    ),
                    selectionColor: const Color(0xFF1A73E8),
                    todayHighlightColor: const Color(0xFF1A73E8),
                    startRangeSelectionColor: const Color(0xFF1A73E8),
                    endRangeSelectionColor: const Color(0xFF1A73E8),
                    rangeSelectionColor: const Color(
                      0xFF1A73E8,
                    ).withOpacity(0.2),

                    onSelectionChanged: (args) {
                      if (args.value is DateTime) {
                        Navigator.of(dialogContext).pop(args.value as DateTime);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// إظهار حوار اختيار التاريخ بشكل Bottom Sheet
  static Future<DateTime?> showBottomSheet({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
  }) async {
    final now = DateTime.now();
    final selectedDate = initialDate ?? DateTime(now.year - 10, 1, 1);

    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // مقبض السحب
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),

                // العنوان
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'اختر التاريخ',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                // تقويم Syncfusion
                Expanded(
                  child: SfDateRangePicker(
                    initialSelectedDate: selectedDate,
                    minDate: minDate ?? DateTime(now.year - 50),
                    maxDate: maxDate ?? DateTime(now.year + 1),
                    showActionButtons: false,
                    showNavigationArrow: true,
                    selectionMode: DateRangePickerSelectionMode.single,

                    // ✅ يبدأ بعرض السنوات
                    view: DateRangePickerView.decade,

                    // ====== تخصيص الألوان ======
                    backgroundColor: Colors.white,
                    headerStyle: const DateRangePickerHeaderStyle(
                      backgroundColor: Colors.white,
                      textStyle: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    monthViewSettings: const DateRangePickerMonthViewSettings(
                      firstDayOfWeek: 6,
                      dayFormat: 'EEE',
                      viewHeaderStyle: DateRangePickerViewHeaderStyle(
                        backgroundColor: Colors.white,
                        textStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    yearCellStyle: const DateRangePickerYearCellStyle(
                      textStyle: TextStyle(color: Colors.black87, fontSize: 14),
                      todayTextStyle: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      leadingDatesTextStyle: TextStyle(color: Colors.black38),
                    ),
                    monthCellStyle: const DateRangePickerMonthCellStyle(
                      textStyle: TextStyle(color: Colors.black87, fontSize: 14),
                      todayTextStyle: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      leadingDatesTextStyle: TextStyle(color: Colors.black38),
                    ),
                    selectionColor: const Color(0xFF1A73E8),
                    todayHighlightColor: const Color(0xFF1A73E8),
                    startRangeSelectionColor: const Color(0xFF1A73E8),
                    endRangeSelectionColor: const Color(0xFF1A73E8),
                    rangeSelectionColor: const Color(
                      0xFF1A73E8,
                    ).withOpacity(0.2),

                    onSelectionChanged: (args) {
                      if (args.value is DateTime) {
                        Navigator.of(sheetContext).pop(args.value as DateTime);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// تنسيق التاريخ
  static String format(DateTime? date, {String pattern = 'yyyy/MM/dd'}) {
    if (date == null) return '';
    return DateFormat(pattern).format(date);
  }
}
