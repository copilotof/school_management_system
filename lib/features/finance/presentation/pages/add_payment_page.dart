import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/widgets/custom_date_picker.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/finance/domain/entities/payment_entity.dart';
import 'package:school_management_system/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_event.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

// ثوابت التصميم
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

// ============================================================
// 🎨 نظام التصميم الموحّد (Design Tokens) — Material 3
// ============================================================

/// مسافات موحّدة عبر كل الصفحة، بدل أرقام متفرقة
class AppSpacing {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
  static double get xl => 24.h;
}

class AppRadius {
  static double get card => 16.r;
  static double get chip => 100.r; // pill shape
  static double get field => 12.r;
  static double get sheet => 24.r;
}

const double _kIconSize = 18;
const double _kSectionIconSize = 16;

/// 🏷️ عنوان قسم داخل بطاقة — أيقونة + نص بنمط موحّد
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: _kSectionIconSize.sp, color: colors.primary),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// 📦 بطاقة تجميع بنمط Material 3 (surface tonal, بلا ظل صارخ)
class _FormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? headerTrailing;

  const _FormCard({
    required this.icon,
    required this.title,
    required this.child,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(icon: icon, title: title, trailing: headerTrailing),
          SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

/// 🔘 شريط الإجراء السفلي الثابت — منفصل بصريًا عن المحتوى، لا يتحرك مع التمرير
/// يدعم إجراء أساسي (Filled) وإجراء ثانوي اختياري (Outlined/Tonal)
class _StickyActionBar extends StatelessWidget {
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondaryPressed;

  const _StickyActionBar({
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.secondaryIcon,
    this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainer,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
          child: Row(
            children: [
              if (secondaryLabel != null) ...[
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: OutlinedButton.icon(
                      onPressed: onSecondaryPressed,
                      icon: Icon(secondaryIcon, size: _kIconSize.sp),
                      label: Text(
                        secondaryLabel!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
              ],
              Expanded(
                flex: secondaryLabel != null ? 2 : 1,
                child: SizedBox(
                  height: 48.h,
                  child: FilledButton.icon(
                    onPressed: onPrimaryPressed,
                    icon: Icon(primaryIcon, size: _kIconSize.sp),
                    label: Text(
                      primaryLabel,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.field),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🏷️ شريحة اختيار نوع العملية — مبنية على منطق FilterChip في M3
class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _TypeChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = selected == value;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 15.sp,
        color: isSelected
            ? colors.onSecondaryContainer
            : colors.onSurfaceVariant,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: isSelected
            ? colors.onSecondaryContainer
            : colors.onSurfaceVariant,
      ),
      selected: isSelected,
      onSelected: (_) => onTap(value),
      selectedColor: colors.secondaryContainer,
      backgroundColor: colors.surfaceContainerLow,
      side: BorderSide(
        color: isSelected ? colors.secondaryContainer : colors.outlineVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      showCheckmark: false,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
    );
  }
}

/// شارة صغيرة لعرض حالة (مثل "مفعّل") بلون ثانوي هادئ
class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: colors.onTertiaryContainer,
        ),
      ),
    );
  }
}

/// 📁 صفحة تسجيل عملية مالية
class AddPaymentPage extends StatefulWidget {
  final StudentEntity student;
  final int groupId;
  final String? initialMonth; // ✅ شهر محدد مسبقاً
  final int? initialExtraSessionId;

  const AddPaymentPage({
    super.key,
    required this.student,
    required this.groupId,
    this.initialMonth,
    this.initialExtraSessionId,
  });

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _amountController = TextEditingController();
  final _reductionController = TextEditingController();
  final _notesController = TextEditingController();
  final _extraDescriptionController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  String _paymentType = 'monthly';
  String _selectedMonth = '';
  bool _isAdvance = false;
  int _advanceMonths = 3;
  double _advanceDiscount = 5;

  int? _selectedExtraId;
  List<PaymentEntity> _unpaidExtras = [];

  static const Map<String, IconData> _typeIcons = {
    'monthly': Icons.calendar_view_month_rounded,
    'exemption': Icons.volunteer_activism_outlined,
    'reduction': Icons.percent_rounded,
    'registration': Icons.how_to_reg_outlined,
    'extra': Icons.add_card_outlined,
  };

  @override
  void initState() {
    super.initState();

    // ✅ إذا كانت حصة إضافية محددة، اختر نوع "إضافية" مباشرة
    if (widget.initialExtraSessionId != null) {
      _paymentType = 'extra';
    }

    // ✅ تعيين الشهر المحدد مسبقاً
    if (widget.initialMonth != null) {
      _selectedMonth = widget.initialMonth!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsBloc>().add(const FetchGroups());
      context.read<EnrollmentBloc>().add(FetchEnrollments());
      context.read<FinanceBloc>().add(FetchAllFinanceData());
      _setDefaultAmount();

      // ✅ إذا كانت حصة إضافية، عيّن المبلغ تلقائياً
      /*       if (widget.initialExtraSessionId != null) {
        _unpaidExtras = _getUnpaidExtraFees();
        final selected = _unpaidExtras
            .where((e) => e.id == widget.initialExtraSessionId)
            .firstOrNull;
        if (selected != null) {
          _amountController.text = selected.remainingAmount.toStringAsFixed(0);
        }
        setState(() {});
      }
 */

      // ✅ إذا كانت حصة إضافية محددة، جلب الحصص واختيار المناسبة
      if (widget.initialExtraSessionId != null) {
        _loadExtraSession();
      }
    });
  }

  /// ✅ جلب واختيار الحصة الإضافية
  void _loadExtraSession() {
    // انتظر قليلاً حتى يتم تحميل البيانات
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final payments =
          context.read<FinanceBloc>().state.paymentsState.data ?? [];
      final unpaidExtras = payments
          .where(
            (p) =>
                p.studentId == widget.student.id &&
                p.groupId == widget.groupId &&
                p.type == 'extra' &&
                p.remainingAmount > 0,
          )
          .toList();

      final selected = unpaidExtras
          .where((e) => e.id == widget.initialExtraSessionId)
          .firstOrNull;

      if (selected != null) {
        setState(() {
          _unpaidExtras = unpaidExtras;
          _selectedExtraId = selected.id;
          _amountController.text = selected.remainingAmount.toStringAsFixed(0);
        });
      } else {
        // الحصة غير موجودة أو مدفوعة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذه الحصة الإضافية مدفوعة بالكامل أو غير موجودة'),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reductionController.dispose();
    _notesController.dispose();
    _extraDescriptionController.dispose();
    super.dispose();
  }

  double _getGroupMonthlyFee() {
    final groups = context.read<GroupsBloc>().state.groupsState.data ?? [];
    final group = groups.where((g) => g.id == widget.groupId).firstOrNull;
    return group?.monthlyFee ?? 0;
  }

  void _setDefaultAmount() {
    final fee = _getGroupMonthlyFee();
    if (_paymentType == 'reduction') {
      _amountController.text = fee.toStringAsFixed(0); // المبلغ الأصلي للعرض
    } else {
      _amountController.text = fee.toStringAsFixed(0);
    }
  }

  DateTime? _getEnrollmentDate() {
    final enrollments =
        context.read<EnrollmentBloc>().state.enrollmentsState.data ?? [];
    final enrollment = enrollments
        .where(
          (e) =>
              e.studentId == widget.student.id &&
              e.groupId == widget.groupId &&
              e.status == 'active',
        )
        .firstOrNull;
    return enrollment?.enrollmentDate;
  }

  List<PaymentEntity> _getUnpaidExtraFees() {
    final payments = context.read<FinanceBloc>().state.paymentsState.data ?? [];
    return payments
        .where(
          (p) =>
              p.studentId == widget.student.id &&
              p.groupId == widget.groupId &&
              p.type == 'extra' &&
              p.remainingAmount > 0,
        )
        .toList();
  }

  /// ✅ الأشهر غير المدفوعة - من التسجيل حتى شهر بعد آخر شهر مدفوع
  List<String> _getUnpaidMonths() {
    final now = DateTime.now();
    final payments = context.read<FinanceBloc>().state.paymentsState.data ?? [];

    final paidMonths = <String>{};
    for (final payment in payments.where(
      (p) => p.studentId == widget.student.id && p.groupId == widget.groupId,
    )) {
      if (payment.monthYear != null) {
        paidMonths.add(payment.monthYear!);
      }
      if (payment.type == 'advance' && payment.notes != null) {
        final match = RegExp(r'(\d{4}-\d{2})').allMatches(payment.notes!);
        final monthList = match.map((m) => m.group(0)!).toList();
        if (monthList.length >= 2) {
          final start = DateTime.parse('${monthList[0]}-01');
          final end = DateTime.parse('${monthList[1]}-01');
          for (
            DateTime d = start;
            !d.isAfter(end);
            d = DateTime(d.year, d.month + 1, 1)
          ) {
            paidMonths.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
          }
        }
      }
    }

    final enrollmentDate =
        _getEnrollmentDate() ?? DateTime(now.year - 1, now.month);
    final startMonth = DateTime(enrollmentDate.year, enrollmentDate.month, 1);

    // ✅ آخر شهر غير مدفوع (لكن ليس بعد الشهر الماضي)
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    DateTime? lastUnpaidMonth;

    for (
      DateTime date = startMonth;
      !date.isAfter(lastMonth);
      date = DateTime(date.year, date.month + 1, 1)
    ) {
      final monthYear = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (!paidMonths.contains(monthYear)) {
        lastUnpaidMonth = date;
      }
    }

    // ✅ نهاية القائمة:
    // - إذا كان هناك أشهر غير مدفوعة: آخر شهر غير مدفوع + 1
    // - إذا لم يكن: الشهر الحالي + 1
    final endMonth = lastUnpaidMonth != null
        ? DateTime(lastUnpaidMonth.year, lastUnpaidMonth.month + 1, 1)
        : DateTime(now.year, now.month + 1, 1);

    final unpaidMonths = <String>[];
    for (
      DateTime date = startMonth;
      !date.isAfter(endMonth);
      date = DateTime(date.year, date.month + 1, 1)
    ) {
      final monthYear = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (!paidMonths.contains(monthYear)) {
        unpaidMonths.add(monthYear);
      }
    }

    // ✅ إذا كانت القائمة فارغة، أضف شهراً واحداً على الأقل (الشهر الحالي + 1)
    if (unpaidMonths.isEmpty) {
      for (
        DateTime date = lastMonth;
        ;
        date = DateTime(date.year, date.month + 1, 1)
      ) {
        final monthYear =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';
        if (!paidMonths.contains(monthYear)) {
          unpaidMonths.add(monthYear);
          if (unpaidMonths.length >= 2) break;
        }
      }
    }

    return unpaidMonths;
  }

  /// ✅ نافذة الدفع المسبق
  void _showAdvanceDialog() async {
    if (_selectedMonth.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار الشهر أولاً')));
      return;
    }
    final monthlyFee = _getGroupMonthlyFee();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _AdvancePaymentDialog(monthlyFee: monthlyFee),
    );

    if (result != null && mounted) {
      setState(() {
        _isAdvance = true;
        _advanceMonths = result['monthsCount'] as int;
        _advanceDiscount = result['discountPercentage'] as double;
        _amountController.text = (result['totalAmount'] as double)
            .toStringAsFixed(0);
      });
    }
  }

  String _generateReceiptNumber() {
    final now = DateTime.now();
    return 'RCP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
  }

  void _submit() {
    var amount = double.tryParse(_amountController.text) ?? 0;
    // ... باقي الحالات (monthly, advance, reduction, registration, extra)
    // if (amount <= 0) return;
    // ✅ الإعفاء لا يحتاج مبلغاً
    if (_paymentType != 'exemption' && amount <= 0) return;

    if ((_paymentType == 'monthly' || _paymentType == 'reduction') &&
        _selectedMonth.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار الشهر')));
      return;
    }
    final monthlyFee = _getGroupMonthlyFee();
    String? monthYear = null;
    String? notes = _notesController.text.isEmpty
        ? null
        : _notesController.text;
    double originalAmount = amount;
    double remainingAmount = 0;
    String type = _paymentType;

    if (_paymentType == 'monthly') {
      monthYear = _selectedMonth;
      if (_isAdvance) {
        type = 'advance';
        final startMonthDate = DateTime.parse('$_selectedMonth-01');
        final endMonthDate = DateTime(
          startMonthDate.year,
          startMonthDate.month + _advanceMonths - 1,
          1,
        );
        notes =
            'دفع مسبق $_advanceMonths أشهر (خصم $_advanceDiscount%) - من $_selectedMonth إلى ${endMonthDate.year}-${endMonthDate.month.toString().padLeft(2, '0')}';
        originalAmount = monthlyFee * _advanceMonths;
        remainingAmount = 0;
      } else {
        originalAmount = monthlyFee;
        if (amount < monthlyFee) {
          remainingAmount = monthlyFee - amount;
          notes = 'دفع جزئي - متبقي ${remainingAmount.toStringAsFixed(0)} دج';
        }
      }
    } else if (_paymentType == 'exemption') {
      if (_selectedMonth.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('يرجى اختيار الشهر')));
        return;
      }

      final monthlyFee = _getGroupMonthlyFee();
      final sessionId = null; // الإعفاء لا يرتبط بحصة
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy/MM/dd').format(now);

      // ✅ إنشاء عملية إعفاء
      final payment = PaymentEntity(
        studentId: widget.student.id!,
        groupId: widget.groupId,
        type: 'exemption',
        monthYear: _selectedMonth,
        amount: 0, // ✅ المدفوع = 0
        originalAmount: monthlyFee, // ✅ الأصلي = رسوم الفوج
        remainingAmount: 0, // ✅ لا متبقي
        paymentDate: _paymentDate,
        method: 'cash',
        receiptNumber: _generateReceiptNumber(),
        notes:
            'إعفاء - ${_notesController.text.isNotEmpty ? _notesController.text : 'بدون سبب'}',
      );

      context.read<FinanceBloc>().add(CreatePaymentEvent(payment));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الإعفاء بنجاح'),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.of(context).pop();
      return;
    } else if (_paymentType == 'reduction') {
      monthYear = _selectedMonth;
      // ✅ المبلغ الأصلي = المبلغ في الحقل (غير قابل للتغيير)
      originalAmount = double.tryParse(_amountController.text) ?? monthlyFee;
      // ✅ المبلغ المدفوع = المبلغ المخفض
      final reducedAmount = double.tryParse(_reductionController.text) ?? 0;
      amount = reducedAmount;
      remainingAmount = 0;
      notes =
          'تخفيض - المطلوب ${originalAmount.toStringAsFixed(0)} دج، دفع ${reducedAmount.toStringAsFixed(0)} دج (مساعدة ${(originalAmount - reducedAmount).toStringAsFixed(0)} دج)${_notesController.text.isNotEmpty ? ' - ${_notesController.text}' : ''}';
    } else if (_paymentType == 'registration') {
      type = 'registration';
      notes = 'رسوم تسجيل سنوية';
    } else if (_paymentType == 'extra') {
      // ✅ تسديد حصة إضافية
      if (_selectedExtraId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار الحصة الإضافية')),
        );
        return;
      }

      final selectedExtra = _unpaidExtras.firstWhere(
        (e) => e.id == _selectedExtraId,
      );
      final payAmount = double.tryParse(_amountController.text) ?? 0;

      if (payAmount <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')));
        return;
      }

      if (payAmount > selectedExtra.remainingAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'المبلغ أكبر من المتبقي (${selectedExtra.remainingAmount.toStringAsFixed(0)} دج)',
            ),
          ),
        );
        return;
      }

      final newRemaining = selectedExtra.remainingAmount - payAmount;

      // 1. تحديث الحصة الإضافية الأصلية
      final updatedExtra = selectedExtra.copyWith(
        amount: selectedExtra.amount + payAmount,
        remainingAmount: newRemaining,
        paymentDate: DateTime.now(),
        notes: newRemaining <= 0 ? 'مدفوع بالكامل' : selectedExtra.notes,
      );

      // 2. إنشاء دفعة منفصلة للسجل
      final payment = PaymentEntity(
        studentId: widget.student.id!,
        groupId: widget.groupId,
        sessionId: selectedExtra.sessionId,
        parentPaymentId: selectedExtra.id, // ✅ ربط بالحصة الأصلية
        type: 'extra_payment',
        amount: payAmount,
        originalAmount: selectedExtra.originalAmount,
        remainingAmount: newRemaining,
        paymentDate: _paymentDate,
        method: 'cash',
        receiptNumber: _generateReceiptNumber(),
        notes: 'تسديد حصة إضافية',
      );

      // إرسال الحدثين
      context.read<FinanceBloc>().add(UpdatePaymentEvent(updatedExtra));
      context.read<FinanceBloc>().add(CreatePaymentEvent(payment));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newRemaining <= 0
                ? 'تم تسديد الحصة الإضافية بالكامل'
                : 'تم تسديد $payAmount دج. المتبقي: $newRemaining دج',
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );

      Navigator.of(context).pop();
      return;
    }

    final payment = PaymentEntity(
      studentId: widget.student.id!,
      groupId: widget.groupId,
      type: type,
      monthYear: monthYear,
      amount: amount,
      originalAmount: originalAmount,
      remainingAmount: remainingAmount,
      paymentDate: _paymentDate,
      method: 'cash',
      receiptNumber: _generateReceiptNumber(),
      notes: notes,
    );

    context.read<FinanceBloc>().add(CreatePaymentEvent(payment));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم تسجيل العملية بنجاح')));
    Navigator.of(context).pop();
  }

  void _changeType(String type) {
    setState(() {
      _paymentType = type;
      _isAdvance = false;
      _selectedExtraId = null;

      if (type == 'monthly') {
        _setDefaultAmount();
      } else if (type == 'reduction') {
        final fee = _getGroupMonthlyFee();
        _amountController.text = fee.toStringAsFixed(0);
        _reductionController.clear();
      } else if (type == 'extra') {
        // ✅ جلب الحصص الإضافية
        _unpaidExtras = _getUnpaidExtraFees();
        _amountController.clear();
      } else {
        _amountController.clear();
      }
    });
  }

  InputDecoration _fieldDecoration({
    IconData? icon,
    String? hint,
    String? suffixText,
  }) {
    return InputDecoration(
      prefixIcon: icon != null ? Icon(icon, size: _kIconSize) : null,
      hintText: hint,
      suffixText: suffixText,
      isDense: true,
      filled: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final unpaidMonths = _getUnpaidMonths();

    return Scaffold(
      appBar: AppBar(
        title: Text('عملية: ${widget.student.fullName}'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ====== نوع العملية ======
            _FormCard(
              icon: Icons.category_outlined,
              title: 'نوع العملية',
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _TypeChip(
                    icon: _typeIcons['monthly']!,
                    label: 'شهرية',
                    value: 'monthly',
                    selected: _paymentType,
                    onTap: _changeType,
                  ),
                  _TypeChip(
                    icon: _typeIcons['exemption']!,
                    label: 'إعفاء',
                    value: 'exemption',
                    selected: _paymentType,
                    onTap: _changeType,
                  ),
                  _TypeChip(
                    icon: _typeIcons['reduction']!,
                    label: 'تخفيض',
                    value: 'reduction',
                    selected: _paymentType,
                    onTap: _changeType,
                  ),
                  _TypeChip(
                    icon: _typeIcons['registration']!,
                    label: 'تسجيل',
                    value: 'registration',
                    selected: _paymentType,
                    onTap: _changeType,
                  ),
                  _TypeChip(
                    icon: _typeIcons['extra']!,
                    label: 'إضافية',
                    value: 'extra',
                    selected: _paymentType,
                    onTap: _changeType,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.sm),

            // ====== الشهر ======
            if (_paymentType == 'monthly' ||
                _paymentType == 'exemption' ||
                _paymentType == 'reduction') ...[
              _FormCard(
                icon: Icons.calendar_month,
                title: 'الشهر',
                child: widget.initialMonth != null
                    ? Container(
                        // ✅ شهر محدد - غير قابل للتغيير
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock, size: 16),
                            SizedBox(width: 8.w),
                            Text(
                              widget.initialMonth!,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: _fieldDecoration(
                          icon: Icons.calendar_month,
                        ),
                        hint: Text(
                          unpaidMonths.isEmpty
                              ? 'لا توجد أشهر غير مدفوعة'
                              : 'اختر الشهر',
                          style: const TextStyle(fontSize: 12),
                        ),
                        items: unpaidMonths.map((monthYear) {
                          return DropdownMenuItem(
                            value: monthYear,
                            child: Text(
                              monthYear,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedMonth = value ?? ''),
                      ),
              ),
              SizedBox(height: AppSpacing.sm),
            ],

            // ====== الدفع المسبق (فقط للشهرية) — إجراء ثانوي واضح ======
            if (_paymentType == 'monthly') ...[
              _FormCard(
                icon: Icons.fast_forward,
                title: 'دفع مسبق',
                headerTrailing: _isAdvance
                    ? const _StatusBadge(label: 'مفعّل')
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 42.h,
                      child: FilledButton.tonalIcon(
                        onPressed: _showAdvanceDialog,
                        icon: const Icon(Icons.fast_forward, size: 16),
                        label: Text(
                          _isAdvance
                              ? 'تعديل الدفع المسبق ($_advanceMonths أشهر)'
                              : 'تحويل لدفع مسبق',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.field,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_isAdvance)
                      Padding(
                        padding: EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'المبلغ محسوب تلقائياً بخصم $_advanceDiscount%',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: colors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.sm),
            ],

            // المبلغ - يظهر فقط لغير الإعفاء
            if (_paymentType != 'exemption' &&
                (_paymentType != 'extra' || _selectedExtraId != null)) ...[
              _FormCard(
                icon: Icons.payments_outlined,
                title: _paymentType == 'reduction'
                    ? 'المبلغ المطلوب (دج)'
                    : 'المبلغ (دج)',
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  readOnly: _isAdvance || _paymentType == 'reduction',
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      _paymentType == 'reduction'
                          ? Icons.lock
                          : Icons.payments_outlined,
                      size: 18,
                    ),
                    isDense: true,
                    filled: _paymentType == 'reduction' || _isAdvance,
                    fillColor: _paymentType == 'reduction' || _isAdvance
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : null,
                    suffixIcon: _paymentType == 'reduction'
                        ? Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
              ),
              // SizedBox(height: AppSpacing.md),
              SizedBox(height: _Gap.md),
            ],

            // ====== مبلغ التخفيض ======
            if (_paymentType == 'reduction') ...[
              _FormCard(
                icon: Icons.percent,
                title: 'المبلغ المخفض (دج)',
                child: TextField(
                  controller: _reductionController,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration(
                    icon: Icons.percent,
                    suffixText: 'دج',
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
            ],

            // ====== عنوان المستحق الإضافي ======
            // بعد _FormCard الخاص بنوع العملية:
            if (_paymentType == 'extra') ...[
              _FormCard(
                icon: Icons.event,
                title: 'الحصة الإضافية',
                child: _unpaidExtras.isEmpty
                    ? Text(
                        'لا توجد حصص إضافية مستحقة لهذا الطالب',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: _selectedExtraId,
                        decoration: const InputDecoration(
                          labelText: 'اختر الحصة *',
                          prefixIcon: Icon(Icons.event, size: 18),
                          isDense: true,
                        ),
                        items: _unpaidExtras.map((extra) {
                          return DropdownMenuItem(
                            value: extra.id,
                            child: Text(
                              'حصة ${DateFormat('yyyy/MM/dd').format(extra.paymentDate)} - متبقي ${extra.remainingAmount.toStringAsFixed(0)} دج',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedExtraId = value;
                            final selected = _unpaidExtras.firstWhere(
                              (e) => e.id == value,
                            );
                            // ✅ المبلغ تلقائياً = المتبقي
                            _amountController.text = selected.remainingAmount
                                .toStringAsFixed(0);
                          });
                        },
                      ),
              ),
              SizedBox(height: _Gap.md),
            ],
            // ====== التاريخ ======
            _FormCard(
              icon: Icons.calendar_today,
              title: 'تاريخ العملية',
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.field),
                onTap: () async {
                  final picked = await CustomDatePicker.showBottomSheet(
                    context: context,
                    initialDate: _paymentDate,
                  );
                  if (picked != null) setState(() => _paymentDate = picked);
                },
                child: InputDecorator(
                  decoration: _fieldDecoration(icon: Icons.calendar_today),
                  child: Text(
                    DateFormat('yyyy/MM/dd').format(_paymentDate),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.sm),

            // ====== ملاحظات ======
            _FormCard(
              icon: Icons.notes,
              title: 'ملاحظات / سبب',
              child: TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: _fieldDecoration(hint: 'اختياري'),
              ),
            ),
          ],
        ),
      ),
      // شريط إجراء ثابت أسفل الشاشة — لا يتحرك مع التمرير، ومنفصل بصريًا بظل خفيف
      bottomNavigationBar: _StickyActionBar(
        primaryLabel: 'تسجيل العملية',
        primaryIcon: Icons.check_circle_outline,
        onPrimaryPressed: _submit,
      ),
    );
  }
}

/// 📁 نافذة الدفع المسبق
class _AdvancePaymentDialog extends StatefulWidget {
  final double monthlyFee;

  const _AdvancePaymentDialog({required this.monthlyFee});

  @override
  State<_AdvancePaymentDialog> createState() => _AdvancePaymentDialogState();
}

class _AdvancePaymentDialogState extends State<_AdvancePaymentDialog> {
  final _monthsController = TextEditingController(text: '3');
  final _discountController = TextEditingController(text: '5');
  int _months = 3;
  double _discount = 5;

  @override
  void dispose() {
    _monthsController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  double get _totalBefore => widget.monthlyFee * _months;
  double get _discountAmount => _totalBefore * _discount / 100;
  double get _totalAfter => _totalBefore - _discountAmount;

  void _setPreset(int months, double discount) {
    setState(() {
      _months = months;
      _discount = discount;
      _monthsController.text = months.toString();
      _discountController.text = discount.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.fast_forward,
                      color: colors.onPrimaryContainer,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'الدفع المسبق',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),

              // عدد الأشهر
              Text(
                'عدد الأشهر',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _months > 1
                        ? () => setState(() {
                            _months--;
                            _monthsController.text = _months.toString();
                          })
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _monthsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null && parsed > 0) {
                          setState(() => _months = parsed);
                        }
                      },
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => setState(() {
                      _months++;
                      _monthsController.text = _months.toString();
                    }),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),

              // أزرار سريعة
              Row(
                children: [
                  _QuickPreset(
                    label: '3 أشهر\nخصم 5%',
                    selected: _months == 3,
                    onTap: () => _setPreset(3, 5),
                  ),
                  SizedBox(width: 8.w),
                  _QuickPreset(
                    label: '6 أشهر\nخصم 10%',
                    selected: _months == 6,
                    onTap: () => _setPreset(6, 10),
                  ),
                  SizedBox(width: 8.w),
                  _QuickPreset(
                    label: '12 شهر\nخصم 15%',
                    selected: _months == 12,
                    onTap: () => _setPreset(12, 15),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),

              // نسبة الخصم
              // استبدل قسم نسبة الخصم بالكامل:
              Text(
                'نسبة التخفيض %',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),

              // ✅ Slider وحده في السطر
              Slider(
                value: _discount.clamp(0, 50),
                min: 0,
                max: 50,
                divisions: 50,
                label: '$_discount%',
                activeColor: colors.primary,
                onChanged: (value) => setState(() {
                  _discount = double.parse(value.toStringAsFixed(0)); // ✅ تقريب
                  _discountController.text = _discount.toStringAsFixed(0);
                }),
              ),
              SizedBox(height: 4.h),

              // ✅ حقل النسبة في سطر منفصل مع نص توضيحي
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'النسبة: ',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(
                    width: 60.w,
                    child: TextField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        suffixText: '%',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 6.h,
                        ),
                      ),
                      onChanged: (value) {
                        final parsed = double.tryParse(value);
                        if (parsed != null && parsed >= 0 && parsed <= 100) {
                          setState(() => _discount = parsed);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),

              // ملخص — بطاقة تونالية موحّدة الشكل مع بقية الصفحة
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  border: Border.all(
                    color: colors.outlineVariant.withOpacity(0.35),
                  ),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'الرسوم الشهرية',
                      value: '${widget.monthlyFee.toStringAsFixed(0)} دج',
                    ),
                    SizedBox(height: 6.h),
                    _SummaryRow(
                      label: 'المبلغ قبل الخصم',
                      value: '${_totalBefore.toStringAsFixed(0)} دج',
                    ),
                    SizedBox(height: 6.h),
                    _SummaryRow(
                      label:
                          'قيمة الخصم (${_discount.toStringAsFixed(0)}%)', // ✅ تقريب النسبة
                      value: '- ${_discountAmount.toStringAsFixed(0)} دج',

                      /*                       label: 'قيمة الخصم ($_discount%)',
                      value: '- ${_discountAmount.toStringAsFixed(0)} دج', */
                    ),
                    Divider(height: 18, color: colors.outlineVariant),
                    _SummaryRow(
                      label: 'المبلغ النهائي',
                      value: '${_totalAfter.toStringAsFixed(0)} دج',
                      isTotal: true,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // زر ثانوي (إلغاء = Text) وزر أساسي (تأكيد = Filled) — تمييز واضح بينهما
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop({
                        'monthsCount': _months,
                        'discountPercentage': _discount,
                        'totalAmount': _totalAfter,
                      }),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                        ),
                      ),
                      child: const Text('تأكيد'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPreset extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickPreset({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: selected
                ? colors.secondaryContainer
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: selected
                  ? colors.secondaryContainer
                  : colors.outlineVariant,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5.sp,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected
                  ? colors.onSecondaryContainer
                  : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ✅ منع overflow
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 13.sp : 12.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 15.sp : 12.sp,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: color ?? colors.onSurface,
          ),
        ),
      ],
    );
  }
}
