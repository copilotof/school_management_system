import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/widgets/confirm_dialog.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/finance/domain/entities/payment_entity.dart';
import 'package:school_management_system/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_event.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_state.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

import 'account_statement_page.dart';
import 'add_payment_page.dart';
import 'receipt_page.dart';

// ثوابت التصميم...
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

class StudentFinancePage extends StatefulWidget {
  final StudentEntity student;

  const StudentFinancePage({super.key, required this.student});

  @override
  State<StudentFinancePage> createState() => _StudentFinancePageState();
}

class _StudentFinancePageState extends State<StudentFinancePage> {
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceBloc>().add(FetchAllFinanceData());
      context.read<EnrollmentBloc>().add(FetchEnrollments());
      context.read<GroupsBloc>().add(const FetchGroups());
    });
  }

  Future<void> _deletePayment(PaymentEntity payment) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'تأكيد الحذف',
      message: 'هل أنت متأكد من حذف هذه العملية؟',
    );
    if (confirmed && mounted) {
      context.read<FinanceBloc>().add(DeletePaymentEvent(payment.id!));
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف العملية')));
    }
  }

  /// ✅ نافذة تفاصيل العملية
  void _showPaymentDetails(PaymentEntity payment) {
    final colors = Theme.of(context).colorScheme;
    final isPartial = payment.type == 'monthly' && payment.remainingAmount > 0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 22.sp,
                      color: colors.primary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'تفاصيل العملية',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                _DetailRow(label: 'النوع', value: payment.typeLabel),
                _DetailRow(label: 'الشهر', value: payment.monthYear ?? '-'),
                // ✅ تاريخ تسجيل الدفعة
                _DetailRow(
                  label: 'تاريخ التسجيل',
                  value: DateFormat('yyyy/MM/dd').format(payment.paymentDate),
                ),

                // ✅ عرض المبلغ حسب النوع
                if (payment.type == 'reduction') ...[
                  _DetailRow(
                    label: 'المبلغ المدفوع',
                    value: '${payment.amount.toStringAsFixed(0)} دج',
                  ),
                  _DetailRow(
                    label: 'المبلغ الأصلي',
                    value: '${payment.originalAmount.toStringAsFixed(0)} دج',
                  ),
                  _DetailRow(
                    label: 'مساعدة من المدرسة',
                    value:
                        '${(payment.originalAmount - payment.amount).toStringAsFixed(0)} دج',
                    color: colors.tertiary,
                  ),
                ] else ...[
                  _DetailRow(
                    label: 'المبلغ المدفوع',
                    value: '${payment.amount.toStringAsFixed(0)} دج',
                  ),
                  if (payment.originalAmount > 0)
                    _DetailRow(
                      label: 'المبلغ الإجمالي',
                      value: '${payment.originalAmount.toStringAsFixed(0)} دج',
                    ),
                ],

                if (isPartial) ...[
                  Divider(color: colors.outlineVariant),
                  _DetailRow(
                    label: 'المتبقي',
                    value: '${payment.remainingAmount.toStringAsFixed(0)} دج',
                    color: colors.error,
                  ),
                ],

                if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                  Divider(color: colors.outlineVariant),
                  Text(
                    payment.notes!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                // بعد الأزرار الموجودة
                if (payment.type != 'exemption') ...[
                  SizedBox(height: 6.h),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReceiptPage(
                            payment: payment,
                            student: widget.student,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: const Text('عرض الإيصال'),
                  ),
                ],

                SizedBox(height: 16.h),

                if (isPartial) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _settleRemaining(payment);
                    },
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('تم تسديد الباقي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.secondary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                ],

                OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء الأمر'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ تسديد الباقي - مع تحديث الملاحظة
  void _settleRemaining(PaymentEntity payment) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy/MM/dd').format(now);

    final updatedPayment = PaymentEntity(
      id: payment.id,
      studentId: payment.studentId,
      groupId: payment.groupId,
      type: payment.type,
      monthYear: payment.monthYear,
      amount: payment.originalAmount,
      originalAmount: payment.originalAmount,
      remainingAmount: 0,
      paymentDate: now, // ✅ تحديث التاريخ
      method: payment.method,
      receiptNumber: payment.receiptNumber,
      // ✅ تغيير الملاحظة
      notes: 'تم تسديد الباقي بتاريخ: $dateStr',
      recordedBy: payment.recordedBy,
    );

    context.read<FinanceBloc>().add(UpdatePaymentEvent(updatedPayment));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم تسديد الباقي بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.student.fullName)),
      body: BlocBuilder<EnrollmentBloc, EnrollmentState>(
        builder: (context, enrollmentState) {
          return BlocBuilder<GroupsBloc, GroupsState>(
            builder: (context, groupsState) {
              final enrollments = enrollmentState.enrollmentsState.data ?? [];
              final groups = groupsState.groupsState.data ?? [];

              final studentEnrollments = enrollments
                  .where(
                    (e) =>
                        e.studentId == widget.student.id &&
                        e.status == 'active',
                  )
                  .toList();

              final studentGroups = groups
                  .where(
                    (g) => studentEnrollments.any((e) => e.groupId == g.id),
                  )
                  .toList();

              if (_selectedGroupId == null && studentGroups.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _selectedGroupId = studentGroups.first.id);
                  }
                });
              }

              return SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStudentCard(colors),
                    SizedBox(height: _Gap.lg),

                    if (studentGroups.isEmpty)
                      _buildEmptyCard(colors, 'الطالب غير مسجل في أي فوج')
                    else ...[
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        value: _selectedGroupId,
                        decoration: const InputDecoration(
                          labelText: 'اختر الفوج',
                          prefixIcon: Icon(Icons.groups_outlined, size: 18),
                          isDense: true,
                        ),
                        items: studentGroups.map((group) {
                          return DropdownMenuItem(
                            value: group.id,
                            child: Text(
                              group.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedGroupId = value);
                        },
                      ),
                      SizedBox(height: _Gap.lg),
                      // ✅ زر كشف الحساب
                      SizedBox(height: 8.h),
                      BlocBuilder<GroupsBloc, GroupsState>(
                        builder: (context, groupsState) {
                          final groups = groupsState.groupsState.data ?? [];
                          final selectedGroup = groups
                              .where((g) => g.id == _selectedGroupId)
                              .firstOrNull;

                          if (selectedGroup == null)
                            return const SizedBox.shrink();

                          return OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AccountStatementPage(
                                    student: widget.student,
                                    group: selectedGroup,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.receipt_long, size: 16),
                            label: const Text('عرض كشف الحساب'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(double.infinity, 40.h),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: _Gap.md),
                    ],

                    /*                     if (_selectedGroupId != null)
                    
                      BlocBuilder<FinanceBloc, FinanceState>(
                        builder: (context, financeState) {
                          final payments =
                              (financeState.paymentsState.data ?? [])
                                  .where(
                                    (p) =>
                                        p.studentId == widget.student.id &&
                                        p.groupId == _selectedGroupId,
                                  )
                                  .toList()
                                  .reversed
                                  .toList();

                          final totalPaid = payments
                              .where((p) => p.type != 'exemption')
                              .fold<double>(0, (sum, p) => sum + p.amount);

                          final totalRemaining = payments
                              .where(
                                (p) =>
                                    p.type == 'monthly' &&
                                    p.remainingAmount > 0,
                              )
                              .fold<double>(
                                0,
                                (sum, p) => sum + p.remainingAmount,
                              );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _SummaryChip(
                                      label: 'المدفوع',
                                      value:
                                          '${totalPaid.toStringAsFixed(0)} دج',
                                      icon: Icons.check_circle,
                                      color: colors.secondary,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: _SummaryChip(
                                      label: 'المتبقي',
                                      value:
                                          '${totalRemaining.toStringAsFixed(0)} دج',
                                      icon: Icons.warning_amber,
                                      color: totalRemaining > 0
                                          ? colors.error
                                          : colors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: _Gap.lg),

                              const _SectionHeader(
                                icon: Icons.history,
                                title: 'السجل المالي للفوج',
                              ),
                              SizedBox(height: _Gap.sm),

                              if (payments.isEmpty)
                                _buildEmptyCard(
                                  colors,
                                  'لا توجد عمليات مالية لهذا الفوج',
                                )
                              else
                                ...payments.map(
                                  (payment) => _PaymentHistoryCard(
                                    payment: payment,
                                    onTap: () => _showPaymentDetails(payment),
                                    onDelete: () => _deletePayment(payment),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                  */
                    if (_selectedGroupId != null)
                      BlocBuilder<FinanceBloc, FinanceState>(
                        builder: (context, financeState) {
                          // ✅ كل الدفعات لهذا الطالب في هذا الفوج
                          final allPayments =
                              (financeState.paymentsState.data ?? [])
                                  .where(
                                    (p) =>
                                        p.studentId == widget.student.id &&
                                        p.groupId == _selectedGroupId,
                                  )
                                  .toList();

                          // ✅ تجميع الدفعات
                          final regularPayments = allPayments
                              .where(
                                (p) =>
                                    p.type != 'extra_payment' &&
                                    p.type != 'extra',
                              )
                              .toList()
                              .reversed
                              .toList();

                          final extraSessions = allPayments
                              .where((p) => p.type == 'extra')
                              .toList()
                              .reversed
                              .toList();

                          final extraPayments = allPayments
                              .where((p) => p.type == 'extra_payment')
                              .toList();

                          // ✅ حسابات الملخص
                          final totalPaid = allPayments
                              .where(
                                (p) =>
                                    p.type != 'exemption' &&
                                    p.type != 'extra_payment',
                              )
                              .fold<double>(0, (sum, p) => sum + p.amount);

                          final totalRemaining = allPayments
                              .where(
                                (p) =>
                                    p.remainingAmount > 0 &&
                                    p.type != 'extra_payment',
                              )
                              .fold<double>(
                                0,
                                (sum, p) => sum + p.remainingAmount,
                              );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ====== الملخص ======
                              Row(
                                children: [
                                  Expanded(
                                    child: _SummaryChip(
                                      label: 'المدفوع',
                                      value:
                                          '${totalPaid.toStringAsFixed(0)} دج',
                                      icon: Icons.check_circle,
                                      color: colors.secondary,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: _SummaryChip(
                                      label: 'المتبقي',
                                      value:
                                          '${totalRemaining.toStringAsFixed(0)} دج',
                                      icon: Icons.warning_amber,
                                      color: totalRemaining > 0
                                          ? colors.error
                                          : colors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: _Gap.lg),

                              const _SectionHeader(
                                icon: Icons.history,
                                title: 'السجل المالي للفوج',
                              ),
                              SizedBox(height: _Gap.sm),

                              // ✅ إذا لا توجد دفعات
                              if (allPayments.isEmpty)
                                _buildEmptyCard(
                                  colors,
                                  'لا توجد عمليات مالية لهذا الفوج',
                                )
                              else ...[
                                // ====== 1. الدفعات العادية ======
                                ...regularPayments.map(
                                  (payment) => _PaymentHistoryCard(
                                    payment: payment,
                                    onTap: () => _showPaymentDetails(payment),
                                    onDelete: () => _deletePayment(payment),
                                  ),
                                ),

                                // ====== 2. الحصص الإضافية (مع دفعاتها) ======
                                ...extraSessions.map((session) {
                                  final sessionPayments = extraPayments
                                      .where(
                                        (p) => p.parentPaymentId == session.id,
                                      )
                                      .toList();

                                  final isPaid = session.remainingAmount <= 0;

                                  return _ExtraSessionCard(
                                    student: widget.student,
                                    originalExtra: session,
                                    payments: sessionPayments,
                                    onDelete: () => _deletePayment(session),
                                    // ✅ عند الضغط: الانتقال لصفحة الدفع (إذا لم تكن مدفوعة)
                                    onPay: isPaid
                                        ? null
                                        : () => _confirmGoToPayment(
                                            context,
                                            session,
                                          ),

                                    /* () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => AddPaymentPage(
                                                  student: widget.student,
                                                  groupId: _selectedGroupId!,
                                                  initialExtraSessionId:
                                                      session.id,
                                                ),
                                              ),
                                            );
                                          }, */
                                  );
                                }),
                              ],
                            ],
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// ✅ تأكيد الذهاب لدفع الحصة الإضافية
  Future<void> _confirmGoToPayment(
    BuildContext context,
    PaymentEntity extraSession,
  ) async {
    final colors = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسديد حصة إضافية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل تريد الانتقال لصفحة الدفع لتسديد هذه الحصة الإضافية؟'),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: colors.tertiaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'التاريخ: ${DateFormat('yyyy/MM/dd').format(extraSession.paymentDate)}',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Text(
                    'المبلغ: ${extraSession.originalAmount.toStringAsFixed(0)} دج',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Text(
                    'المتبقي: ${extraSession.remainingAmount.toStringAsFixed(0)} دج',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: colors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.payment, size: 16),
            label: const Text('تسديد الآن'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddPaymentPage(
            student: widget.student,
            groupId: _selectedGroupId!,
            initialExtraSessionId: extraSession.id,
          ),
        ),
      );
    }
  }

  Widget _buildStudentCard(ColorScheme colors) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withOpacity(0.8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              widget.student.firstName.isNotEmpty
                  ? widget.student.firstName.substring(0, 1)
                  : '؟',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.fullName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'الرقم: ${widget.student.studentCode}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(ColorScheme colors, String message) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.sp, color: colors.onSurfaceVariant),
      ),
    );
  }
}

/// 📊 رقاقة ملخص
class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🏷️ عنوان قسم
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: colors.primary),
        SizedBox(width: 6.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: colors.primary,
          ),
        ),
      ],
    );
  }
}

/// 📁 بطاقة عملية مالية
class _PaymentHistoryCard extends StatelessWidget {
  final PaymentEntity payment;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _PaymentHistoryCard({
    required this.payment,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final (statusColor, statusIcon, statusLabel) = switch (payment.type) {
      'exemption' => (colors.tertiary, Icons.card_giftcard, 'إعفاء'),
      'reduction' => (colors.primary, Icons.percent, 'تخفيض'),
      'advance' => (colors.outline, Icons.fast_forward, 'دفع مسبق'),
      'registration' => (colors.outline, Icons.how_to_reg, 'تسجيل'),
      'extra' => (colors.outline, Icons.add_card, 'إضافية'),
      _ =>
        payment.remainingAmount > 0
            ? (colors.primary, Icons.timelapse, 'جزئي')
            : (colors.secondary, Icons.check_circle, 'مدفوع'),
    };

    // ✅ عرض المبلغ حسب النوع - التخفيض يعرض المبلغ المدفوع
    final displayAmount = payment.amount;

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 6.h),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Row(
            children: [
              Icon(statusIcon, size: 18.sp, color: statusColor),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${displayAmount.toStringAsFixed(0)} دج',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${payment.monthYear ?? ''} | $statusLabel',
                      style: TextStyle(fontSize: 10.5.sp, color: statusColor),
                    ),
                    if (payment.notes != null && payment.notes!.isNotEmpty)
                      Text(
                        payment.notes!,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (payment.remainingAmount > 0 && payment.type == 'monthly')
                Padding(
                  padding: EdgeInsets.only(right: 4.w),
                  child: Text(
                    'متبقي: ${payment.remainingAmount.toStringAsFixed(0)} دج',
                    style: TextStyle(fontSize: 10.sp, color: colors.error),
                  ),
                ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 16.sp,
                  color: colors.error,
                ),
                tooltip: 'حذف',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 📄 صف تفاصيل
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _DetailRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: colors.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: color ?? colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// 📁 بطاقة الحصة الإضافية (مع دفعاتها)
class _ExtraSessionCard extends StatelessWidget {
  final StudentEntity student;
  final PaymentEntity originalExtra;
  final List<PaymentEntity> payments;
  final VoidCallback onDelete;
  final VoidCallback? onPay;

  const _ExtraSessionCard({
    required this.student,
    required this.originalExtra,
    required this.payments,
    required this.onDelete,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPaid = originalExtra.remainingAmount <= 0;
    final statusColor = isPaid ? colors.secondary : colors.error;
    final statusIcon = isPaid ? Icons.check_circle : Icons.timelapse;
    final statusLabel = isPaid
        ? 'مدفوع'
        : 'متبقي ${originalExtra.remainingAmount.toStringAsFixed(0)} دج';

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 6.h),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(color: colors.tertiary.withOpacity(0.3)),
      ),
      child: InkWell(
        // ✅ إضافة onTap
        borderRadius: BorderRadius.circular(10.r),
        onTap: onPay,
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ====== الرأس ======
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 18.sp,
                    color: colors.tertiary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حصة إضافية',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'yyyy/MM/dd',
                          ).format(originalExtra.paymentDate),
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // شارة الحالة
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12.sp, color: statusColor),
                        SizedBox(width: 4.w),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // زر الحذف
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 16.sp,
                      color: colors.error,
                    ),
                    tooltip: 'حذف',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // ====== ملخص المبالغ ======
              Row(
                children: [
                  _MiniInfo(
                    label: 'الأصلي',
                    value:
                        '${originalExtra.originalAmount.toStringAsFixed(0)} دج',
                  ),
                  _MiniInfo(
                    label: 'المدفوع',
                    value: '${originalExtra.amount.toStringAsFixed(0)} دج',
                  ),
                  _MiniInfo(
                    label: 'المتبقي',
                    value:
                        '${originalExtra.remainingAmount.toStringAsFixed(0)} دج',
                    color: originalExtra.remainingAmount > 0
                        ? colors.error
                        : null,
                  ),
                ],
              ),

              // ====== الدفعات ======
              if (payments.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Divider(height: 1, color: colors.outlineVariant),
                SizedBox(height: 6.h),
                ...payments.map(
                  (p) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 12.sp,
                          color: colors.secondary,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${p.amount.toStringAsFixed(0)} دج',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('yyyy/MM/dd').format(p.paymentDate),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // في _ExtraSessionCard، بعد الدفعات
              if (isPaid && payments.isNotEmpty) ...[
                SizedBox(height: 8.h),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReceiptPage(
                          payment: payments.last, // آخر دفعة
                          student: student,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, size: 14),
                  label: const Text(
                    'عرض الإيصال',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size(0, 30.h),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 📊 معلومة صغيرة
class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MiniInfo({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9.sp, color: colors.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: color ?? colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
