import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_management_system/features/finance/domain/entities/payment_entity.dart';
import 'package:school_management_system/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:school_management_system/features/finance/presentation/pages/student_finance_page.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_event.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_state.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_state.dart';

import '../../../../core/states/ui_state.dart';
import '../../../../injection_container.dart';
import '../../../attendance/domain/entities/session_entity.dart';
import '../../../enrollment/domain/entities/enrollment_entity.dart';
import '../../../groups/domain/entities/group_entity.dart';
import '../../../notifications/services/auto_notification_service.dart';
import 'add_payment_page.dart';

// ============================================================
// 🎨 ثوابت التصميم
// ============================================================
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 الصفحة المالية الرئيسية
class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ✅ إعادة حساب المالية عند تغيير التسجيلات
        BlocListener<EnrollmentBloc, EnrollmentState>(
          listener: (context, state) {
            if (state.enrollmentsState is Success ||
                state.enrollmentsState is Empty) {
              context.read<FinanceBloc>().add(FetchAllFinanceData());
            }
          },
        ),
      ],
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('الإدارة المالية'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined),
                tooltip: 'فحص المتأخرات',
                onPressed: () async {
                  final count = await getIt<AutoNotificationService>()
                      .checkPaymentOverdue();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          count > 0
                              ? 'تم إنشاء $count إشعار دفع'
                              : 'لا توجد متأخرات جديدة',
                        ),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث',
                onPressed: () {
                  context.read<FinanceBloc>().add(FetchAllFinanceData());
                  context.read<EnrollmentBloc>().add(FetchEnrollments());
                },
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(
                  text: 'الطلبة والتسجيل',
                  icon: Icon(Icons.people_outline, size: 18),
                ),
                Tab(
                  text: 'المعلومات المالية',
                  icon: Icon(Icons.bar_chart, size: 18),
                ),
              ],
            ),
          ),
          body: const TabBarBody(),
        ),
      ),
    );
  }
}

/// ✅ Widget منفصل لتفعيل postFrameCallback
class TabBarBody extends StatefulWidget {
  const TabBarBody({super.key});

  @override
  State<TabBarBody> createState() => _TabBarBodyState();
}

class _TabBarBodyState extends State<TabBarBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ جلب كل البيانات عند فتح الصفحة
      context.read<FinanceBloc>().add(FetchAllFinanceData());
      context.read<EnrollmentBloc>().add(FetchEnrollments());
      context.read<StudentsBloc>().add(const FetchStudents());
      context.read<GroupsBloc>().add(const FetchGroups());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const TabBarView(
      children: [StudentsByGroupTab(), FinanceSummaryTab()],
    );
  }
}

/* 
class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ✅ عند تغيير التسجيلات، أعد حساب الإحصائيات
        BlocListener<EnrollmentBloc, EnrollmentState>(
          listener: (context, state) {
            if (state.enrollmentsState is Success ||
                state.enrollmentsState is Empty) {
              context.read<FinanceBloc>().add(FetchAllFinanceData());
            }
          },
        ),
      ],
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('الإدارة المالية'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث',
                onPressed: () {
                  context.read<FinanceBloc>().add(FetchAllFinanceData());
                  context.read<EnrollmentBloc>().add(FetchEnrollments());
                },
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'الطلبة والتسجيل', icon: Icon(Icons.people_outline, size: 18)),
                Tab(text: 'المعلومات المالية', icon: Icon(Icons.bar_chart, size: 18)),
              ],
            ),
          ),
          body: const TabBarView(
            children: [StudentsByGroupTab(), FinanceSummaryTab()],
          ),
        ),
      ),
    );
  }
}
 */
// ============================================================
// 📁 تبويب الطلبة حسب الأفواج
// ============================================================
class StudentsByGroupTab extends StatefulWidget {
  const StudentsByGroupTab({super.key});

  @override
  State<StudentsByGroupTab> createState() => _StudentsByGroupTabState();
}

class _StudentsByGroupTabState extends State<StudentsByGroupTab> {
  int? _selectedGroupId;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(12.w),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(_kRadius),
            border: Border.all(color: colors.outlineVariant.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              BlocBuilder<GroupsBloc, GroupsState>(
                builder: (context, groupsState) {
                  final groups = groupsState.groupsState.data ?? [];

                  if (groups.isEmpty) {
                    return Text(
                      'لا توجد أفواج',
                      style: TextStyle(color: colors.error),
                    );
                  }

                  if (_selectedGroupId == null && groups.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _selectedGroupId = groups.first.id);
                    });
                  }

                  return DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedGroupId,
                    decoration: InputDecoration(
                      labelText: 'اختر الفوج',
                      prefixIcon: const Icon(Icons.groups_outlined, size: 18),
                      isDense: true,
                    ),
                    items: groups.map((group) {
                      return DropdownMenuItem(
                        value: group.id,
                        child: Text(
                          group.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedGroupId = value),
                  );
                },
              ),
              SizedBox(height: _Gap.sm),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'ابحث عن طالب...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedGroupId == null
              ? const Center(child: Text('اختر فوجاً'))
              : _buildStudentList(context),
        ),
      ],
    );
  }

  Widget _buildStudentList(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      builder: (context, enrollmentState) {
        return BlocBuilder<StudentsBloc, StudentsState>(
          builder: (context, studentsState) {
            final allStudents = studentsState.studentsState.data ?? [];
            final enrollments = enrollmentState.enrollmentsState.data ?? [];

            final enrolledStudentIds = enrollments
                .where(
                  (e) => e.groupId == _selectedGroupId && e.status == 'active',
                )
                .map((e) => e.studentId)
                .toSet();

            final groupStudents = allStudents
                .where((s) => enrolledStudentIds.contains(s.id))
                .toList();

            final filteredStudents = _searchQuery.isEmpty
                ? groupStudents
                : groupStudents
                      .where(
                        (s) =>
                            s.fullName.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            s.studentCode.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                      )
                      .toList();

            if (filteredStudents.isEmpty) {
              return Center(
                child: Text(
                  _searchQuery.isEmpty
                      ? 'لا يوجد طلاب في هذا الفوج'
                      : 'لا توجد نتائج',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                return _StudentFinanceCard(
                  student: student,
                  groupId: _selectedGroupId!,
                  onAddPayment: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddPaymentPage(
                          student: student,
                          groupId: _selectedGroupId!,
                        ),
                      ),
                    );
                  },
                  onViewDetails: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentFinancePage(student: student),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

/// 📁 بطاقة طالب للدفع - مع أزرار واضحة
class _StudentFinanceCard extends StatelessWidget {
  final StudentEntity student;
  final int groupId;
  final VoidCallback onAddPayment;
  final VoidCallback onViewDetails;

  const _StudentFinanceCard({
    required this.student,
    required this.groupId,
    required this.onAddPayment,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Row(
          children: [
            // صورة الطالب
            CircleAvatar(
              radius: 22.r,
              backgroundColor: colors.primaryContainer,
              child: Text(
                student.firstName.isNotEmpty
                    ? student.firstName.substring(0, 1)
                    : '؟',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            // معلومات الطالب
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'الرقم: ${student.studentCode}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // ✅ زران واضحان وكبيران
            Column(
              children: [
                // زر إضافة دفعة
                ElevatedButton.icon(
                  onPressed: onAddPayment,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('دفعة', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.secondary,
                    foregroundColor: Colors.white,
                    minimumSize: Size(70.w, 30.h),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                // زر عرض الحالة
                OutlinedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('الحالة', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    minimumSize: Size(70.w, 30.h),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 📁 تبويب المعلومات المالية
// ============================================================
class FinanceSummaryTab extends StatelessWidget {
  const FinanceSummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                children: [
                  _LargeStatCard(
                    title: 'إجمالي الإيرادات',
                    value: state.totalRevenue.toStringAsFixed(0),
                    unit: 'دج',
                    icon: Icons.trending_up,
                    color: colors.secondary,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: _LargeStatCard(
                          title: 'المتأخرات',
                          value: state.totalOutstanding.toStringAsFixed(0),
                          unit: 'دج',
                          icon: Icons.warning_amber,
                          color: colors.error,
                          isCompact: true,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _LargeStatCard(
                          title: 'الإعفاءات',
                          value: _calculateTotalExemptions(state),
                          unit: 'دج',
                          icon: Icons.card_giftcard,
                          color: colors.tertiary,
                          isCompact: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: colors.primary,
                      unselectedLabelColor: colors.onSurfaceVariant,
                      indicatorColor: colors.primary,
                      tabs: const [
                        Tab(text: 'المدينون'),
                        Tab(text: 'إعفاءات/تخفيضات'),
                      ],
                    ),
                    const Expanded(
                      child: TabBarView(
                        children: [_DebtorsList(), _GiftedList()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ حساب إجمالي الإعفاءات من العمليات
  String _calculateTotalExemptions(FinanceState state) {
    final payments = state.paymentsState.data ?? [];
    final exemptions = payments.where(
      (p) => p.type == 'exemption' || p.type == 'reduction',
    );
    final total = exemptions.fold<double>(
      0,
      (sum, p) => sum + (p.originalAmount - p.amount),
    );
    return total.toStringAsFixed(0);
  }
}

/// 📁 بطاقة إحصائية
class _LargeStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isCompact;

  const _LargeStatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(isCompact ? 10.w : 14.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 6.w : 8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: isCompact ? 16.sp : 20.sp, color: color),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 10.sp : 11.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$value $unit',
                    style: TextStyle(
                      fontSize: isCompact ? 14.sp : 18.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
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

// ============================================================
// 📁 قائمة المدينين - مصححة
// ============================================================
class _DebtorsList extends StatefulWidget {
  const _DebtorsList();

  @override
  State<_DebtorsList> createState() => _DebtorsListState();
}

class _DebtorsListState extends State<_DebtorsList> {
  int? _selectedGroupId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.w),
          child: Row(
            children: [
              Expanded(
                child: BlocBuilder<GroupsBloc, GroupsState>(
                  builder: (context, groupsState) {
                    final groups = groupsState.groupsState.data ?? [];

                    // ✅ تعيين الفوج الأول تلقائياً
                    if (_selectedGroupId == null && groups.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted)
                          setState(() => _selectedGroupId = groups.first.id);
                      });
                    }

                    return DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _selectedGroupId,
                      decoration: InputDecoration(
                        labelText: 'الفوج',
                        isDense: true,
                        prefixIcon: const Icon(Icons.filter_list, size: 16),
                      ),
                      items: groups
                          .map(
                            (g) => DropdownMenuItem(
                              value: g.id!,
                              child: Text(
                                g.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedGroupId = value),
                    );
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'بحث...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: BlocBuilder<FinanceBloc, FinanceState>(
            builder: (context, financeState) {
              return BlocBuilder<EnrollmentBloc, EnrollmentState>(
                builder: (context, enrollmentState) {
                  final payments = financeState.paymentsState.data ?? [];
                  final enrollments =
                      enrollmentState.enrollmentsState.data ?? [];
                  final students =
                      context.read<StudentsBloc>().state.studentsState.data ??
                      [];
                  final groups =
                      context.read<GroupsBloc>().state.groupsState.data ?? [];

                  // ✅ حساب المديونية لكل طالب - الأشهر المتأخرة
                  final debtorMap =
                      <int, List<String>>{}; // studentId -> الأشهر المتأخرة
                  // ✅ حساب المديونية لكل طالب - الأشهر غير المدفوعة + العمليات الجزئية + الحصص الإضافية
                  final debtorMonthsMap = <int, List<String>>{};
                  final debtorPartialMap = <int, List<PaymentEntity>>{};
                  final studentGroupMap = <int, int>{};
                  final studentSessionMap =
                      <int, SessionEntity?>{}; // ✅ للربط بالحصة

                  for (final enrollment in enrollments.where(
                    (e) => e.status == 'active',
                  )) {
                    if (_selectedGroupId != null &&
                        enrollment.groupId != _selectedGroupId)
                      continue;

                    final group = groups
                        .where((g) => g.id == enrollment.groupId)
                        .firstOrNull;
                    if (group == null) continue;

                    // 1. الأشهر غير المدفوعة
                    final unpaidMonths = _getUnpaidMonthsForStudent(
                      enrollment.studentId,
                      enrollment.groupId,
                      payments,
                      enrollments,
                    );

                    // 2. الدفعات الجزئية + الحصص الإضافية
                    final partialPayments = payments
                        .where(
                          (p) =>
                              p.studentId == enrollment.studentId &&
                              p.groupId == enrollment.groupId &&
                              p.remainingAmount > 0 &&
                              (p.type == 'monthly' || p.type == 'extra'),
                        ) // ✅ أضف extra
                        .toList();

                    if (unpaidMonths.isNotEmpty || partialPayments.isNotEmpty) {
                      debtorMonthsMap[enrollment.studentId] = unpaidMonths;
                      debtorPartialMap[enrollment.studentId] = partialPayments;
                      studentGroupMap[enrollment.studentId] =
                          enrollment.groupId;
                    }
                  }
                  final allDebtorIds = {
                    ...debtorMonthsMap.keys,
                    ...debtorPartialMap.keys,
                  };
                  var debtors = students
                      .where((s) => allDebtorIds.contains(s.id))
                      .toList();

                  if (_searchQuery.isNotEmpty) {
                    debtors = debtors
                        .where(
                          (s) =>
                              s.fullName.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              s.studentCode.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                        )
                        .toList();
                  }

                  if (debtors.isEmpty) {
                    return const Center(child: Text('لا يوجد مدينون'));
                  }

                  return ListView.builder(
                    itemCount: debtors.length,
                    itemBuilder: (context, index) {
                      final student = debtors[index];
                      final unpaidMonths = debtorMonthsMap[student.id] ?? [];
                      final partialPayments =
                          debtorPartialMap[student.id] ?? [];
                      final groupId = studentGroupMap[student.id];
                      final group = groups
                          .where((g) => g.id == groupId)
                          .firstOrNull;

                      // ✅ إجمالي المتأخرات = (عدد الأشهر غير المدفوعة × رسوم الفوج) + مجموع remainingAmount
                      final unpaidAmount =
                          unpaidMonths.length * (group?.monthlyFee ?? 0);
                      final partialAmount = partialPayments.fold<double>(
                        0,
                        (sum, p) => sum + p.remainingAmount,
                      );
                      final totalDebt = unpaidAmount + partialAmount;

                      final totalCount =
                          unpaidMonths.length + partialPayments.length;

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16.r,
                            child: Text(student.firstName.substring(0, 1)),
                          ),
                          title: Text(
                            student.fullName,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            '$totalCount أشهر/دفعات متأخرة${group != null ? ' | ${group.name}' : ''}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text(
                            '${totalDebt.toStringAsFixed(0)} دج',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: colors.error,
                            ),
                          ),
                          onTap: () {
                            _showDebtorDetails(
                              context,
                              student,
                              unpaidMonths,
                              partialPayments,
                              group,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// ✅ الأشهر غير المدفوعة من التسجيل حتى الشهر الماضي
  List<String> _getUnpaidMonthsForStudent(
    int studentId,
    int groupId,
    List<PaymentEntity> payments,
    List<EnrollmentEntity> enrollments,
  ) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    final enrollment = enrollments
        .where(
          (e) =>
              e.studentId == studentId &&
              e.groupId == groupId &&
              e.status == 'active',
        )
        .firstOrNull;

    final enrollmentDate =
        enrollment?.enrollmentDate ?? DateTime(now.year - 1, now.month);
    final startMonth = DateTime(enrollmentDate.year, enrollmentDate.month, 1);

    final paidMonths = <String>{};
    for (final payment in payments.where(
      (p) => p.studentId == studentId && p.groupId == groupId,
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

    final unpaidMonths = <String>[];
    for (
      DateTime date = startMonth;
      !date.isAfter(lastMonth);
      date = DateTime(date.year, date.month + 1, 1)
    ) {
      final monthYear = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (!paidMonths.contains(monthYear)) {
        unpaidMonths.add(monthYear);
      }
    }
    return unpaidMonths;
  }

  /// ✅ نافذة التفاصيل مع الأشهر المتأخرة
  void _showDebtorDetails(
    BuildContext context,
    StudentEntity student,
    List<String> unpaidMonths,
    List<PaymentEntity> partialPayments,
    GroupEntity? group,
  ) {
    final colors = Theme.of(context).colorScheme;
    final monthlyFee = group?.monthlyFee ?? 0;
    final unpaidAmount = unpaidMonths.length * (group?.monthlyFee ?? 0);
    final partialAmount = partialPayments.fold<double>(
      0,
      (sum, p) => sum + p.remainingAmount,
    );
    final totalDebt = unpaidAmount + partialAmount;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20.r,
                        backgroundColor: colors.errorContainer,
                        child: Text(
                          student.firstName.substring(0, 1),
                          style: TextStyle(
                            color: colors.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.fullName,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (group != null)
                              Text(
                                'الفوج: ${group.name}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            Text(
                              'إجمالي المتأخرات: ${totalDebt.toStringAsFixed(0)} دج',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: colors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // ✅ الأشهر غير المدفوعة
                  if (unpaidMonths.isNotEmpty) ...[
                    Text(
                      'أشهر غير مدفوعة:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: colors.error,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    // ✅ الأشهر غير المدفوعة - عند الضغط: تسديد الدفعة
                    ...unpaidMonths.map((monthYear) {
                      return InkWell(
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddPaymentPage(
                                student: student,
                                groupId: group!.id!,
                                initialMonth: monthYear, // ✅ تمرير الشهر
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 6.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: colors.error.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16.sp,
                                color: colors.error,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  '$monthYear',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '$monthlyFee دج',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: colors.error,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12.sp,
                                color: colors.error,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 12.h),
                  ],

                  // ✅ الدفعات الجزئية
                  if (partialPayments.isNotEmpty) ...[
                    Text(
                      'دفعات جزئية:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: colors.error,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    // ✅ الدفعات الجزئية - عند الضغط: تسديد الباقي
                    ...partialPayments.map((payment) {
                      final isExtra = payment.type == 'extra';
                      return InkWell(
                        onTap: () {
                          Navigator.of(dialogContext).pop(); // إغلاق الحوار
                          if (isExtra) {
                            // ✅ حصة إضافية: فتح حوار تأكيد
                            _confirmExtraPayment(context, student, payment);
                          } else {
                            // دفعة شهرية جزئية: عرض نافذة تسديد الباقي
                            _showPartialDetails(
                              context,
                              payment,
                              dialogContext,
                            );
                          }
                          borderRadius:
                          BorderRadius.circular(10.r);
                        },
                        child: Container(
                          // ...
                          child: Row(
                            children: [
                              Icon(
                                isExtra
                                    ? Icons.payments_outlined
                                    : Icons.timelapse,
                                size: 16.sp,
                                color: isExtra
                                    ? colors.tertiary
                                    : colors.primary,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isExtra
                                          ? 'حصة إضافية'
                                          : '${payment.monthYear ?? ''}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'دفع: ${payment.amount.toStringAsFixed(0)} دج',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'متبقي: ${payment.remainingAmount.toStringAsFixed(0)} دج',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: colors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudentFinancePage(student: student),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('الحالة المالية'),
                  ),
                  SizedBox(height: 6.h),
                  OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ✅ تأكيد دفع الحصة الإضافية من قائمة المدينين
Future<void> _confirmExtraPayment(
  BuildContext context,
  StudentEntity student,
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
          Text('الطالب: ${student.fullName}'),
          SizedBox(height: 8.h),
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
          student: student,
          groupId: extraSession.groupId!,
          initialExtraSessionId: extraSession.id,
        ),
      ),
    );
  }
}

/// ✅ نافذة تسديد الباقي
void _showPartialDetails(
  BuildContext context,
  PaymentEntity payment,
  BuildContext parentDialogContext,
) {
  final colors = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timelapse, color: colors.error),
            SizedBox(width: 8.w),
            const Text('دفعة جزئية'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الشهر: ${payment.monthYear ?? '-'}'),
            SizedBox(height: 4.h),
            Text('المدفوع: ${payment.amount.toStringAsFixed(0)} دج'),
            SizedBox(height: 4.h),
            Text(
              'المتبقي: ${payment.remainingAmount.toStringAsFixed(0)} دج',
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء الأمر'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(parentDialogContext).pop();
              _settlePartial(context, payment);
            },
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('تم تسديد الباقي'),
            style: ElevatedButton.styleFrom(backgroundColor: colors.secondary),
          ),
        ],
      );
    },
  );
}

/// ✅ تسديد الباقي
void _settlePartial(BuildContext context, PaymentEntity payment) {
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
    paymentDate: now,
    method: payment.method,
    receiptNumber: payment.receiptNumber,
    notes: 'تم تسديد الباقي بتاريخ: $dateStr',
    recordedBy: payment.recordedBy,
  );

  context.read<FinanceBloc>().add(UpdatePaymentEvent(updatedPayment));
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('تم تسديد الباقي بنجاح')));
}

// ============================================================
// 📁 قائمة الإعفاءات/التخفيضات - مبسطة
// ============================================================
class _GiftedList extends StatefulWidget {
  const _GiftedList();

  @override
  State<_GiftedList> createState() => _GiftedListState();
}

class _GiftedListState extends State<_GiftedList> {
  int? _selectedGroupId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ✅ تصفية و بحث
        Padding(
          padding: EdgeInsets.all(8.w),
          child: Row(
            children: [
              Expanded(
                child: BlocBuilder<GroupsBloc, GroupsState>(
                  builder: (context, groupsState) {
                    final groups = groupsState.groupsState.data ?? [];
                    if (_selectedGroupId == null && groups.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted)
                          setState(() => _selectedGroupId = groups.first.id);
                      });
                    }
                    return DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _selectedGroupId,
                      decoration: InputDecoration(
                        labelText: 'الفوج',
                        isDense: true,
                        prefixIcon: const Icon(Icons.filter_list, size: 16),
                      ),
                      items: groups
                          .map(
                            (g) => DropdownMenuItem(
                              value: g.id!,
                              child: Text(
                                g.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedGroupId = value),
                    );
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'بحث...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        // قائمة الإعفاءات
        Expanded(
          child: BlocBuilder<FinanceBloc, FinanceState>(
            builder: (context, state) {
              final payments = state.paymentsState.data ?? [];
              final students =
                  context.read<StudentsBloc>().state.studentsState.data ?? [];

              // ✅ تصفية حسب الفوج
              final filtered = payments.where((p) {
                if (p.type != 'exemption' && p.type != 'reduction')
                  return false;
                if (_selectedGroupId != null && p.groupId != _selectedGroupId)
                  return false;
                return true;
              }).toList();

              final exemptedIds = filtered.map((p) => p.studentId).toSet();
              var giftedStudents = students
                  .where((s) => exemptedIds.contains(s.id))
                  .toList();

              // ✅ بحث
              if (_searchQuery.isNotEmpty) {
                giftedStudents = giftedStudents
                    .where(
                      (s) =>
                          s.fullName.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          s.studentCode.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                    )
                    .toList();
              }

              if (giftedStudents.isEmpty) {
                return const Center(child: Text('لا توجد إعفاءات أو تخفيضات'));
              }

              return ListView.builder(
                padding: EdgeInsets.all(8.w),
                itemCount: giftedStudents.length,
                itemBuilder: (context, index) {
                  final student = giftedStudents[index];
                  final studentExemptions = filtered
                      .where((p) => p.studentId == student.id)
                      .toList();
                  final totalExempted = studentExemptions.fold<double>(0, (
                    sum,
                    p,
                  ) {
                    if (p.type == 'exemption') return sum + p.originalAmount;
                    return sum + (p.originalAmount - p.amount);
                  });

                  return Card(
                    margin: EdgeInsets.only(bottom: 6.h),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16.r,
                        backgroundColor: colors.tertiaryContainer,
                        child: Icon(
                          Icons.card_giftcard,
                          size: 16.sp,
                          color: colors.onTertiaryContainer,
                        ),
                      ),
                      title: Text(
                        student.fullName,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        '${studentExemptions.length} إعفاء/تخفيض',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        '${totalExempted.toStringAsFixed(0)} دج',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: colors.tertiary,
                        ),
                      ),
                      onTap: () => _showExemptionDetails(
                        context,
                        student,
                        studentExemptions,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ✅ نافذة تفاصيل الإعفاءات
void _showExemptionDetails(
  BuildContext context,
  StudentEntity student,
  List<PaymentEntity> payments,
) {
  final colors = Theme.of(context).colorScheme;

  // ✅ حساب مبلغ الإعفاء/التخفيض الفعلي
  // للإعفاء الكامل: المبلغ الأصلي كاملاً
  // للتخفيض: المبلغ الأصلي - المبلغ المدفوع
  final totalExempted = payments.fold<double>(0, (sum, p) {
    if (p.type == 'exemption') {
      return sum + p.originalAmount; // إعفاء كامل
    } else if (p.type == 'reduction') {
      return sum + (p.originalAmount - p.amount); // التخفيض = الفرق
    }
    return sum;
  });

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
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: colors.tertiaryContainer,
                    child: Icon(
                      Icons.card_giftcard,
                      size: 18.sp,
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'إجمالي الإعفاءات: ${totalExempted.toStringAsFixed(0)} دج',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: colors.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              ...payments.map((payment) {
                final isExemption = payment.type == 'exemption';
                final exemptedAmount = isExemption
                    ? payment.originalAmount
                    : payment.originalAmount - payment.amount;

                return Container(
                  margin: EdgeInsets.only(bottom: 6.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExemption ? Icons.card_giftcard : Icons.percent,
                        size: 16.sp,
                        color: colors.tertiary,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${payment.monthYear ?? ''} - ${isExemption ? 'إعفاء كامل' : 'تخفيض'}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!isExemption)
                              Text(
                                'دفع: ${payment.amount.toStringAsFixed(0)} دج من أصل ${payment.originalAmount.toStringAsFixed(0)} دج',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${exemptedAmount.toStringAsFixed(0)} دج',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: colors.tertiary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 12.h),
              OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
