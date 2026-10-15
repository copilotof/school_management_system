import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/utils/translation_extension.dart';
import 'package:school_management_system/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:school_management_system/features/finance/presentation/pages/reports/revenue_report_page.dart';
import 'package:school_management_system/features/finance/presentation/pages/reports/outstanding_report_page.dart'
    hide RevenueReportPage;
import 'package:school_management_system/features/finance/presentation/pages/reports/exemptions_report_page.dart'
    hide RevenueReportPage;
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:school_management_system/features/groups/presentation/bloc/groups_event.dart';

class _Gap {
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 صفحة التقارير المالية
class FinancialReportsPage extends StatelessWidget {
  const FinancialReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceBloc>().add(FetchAllFinanceData());
      context.read<StudentsBloc>().add(const FetchStudents());
      context.read<GroupsBloc>().add(const FetchGroups());
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('reports.financialReports')),
          bottom: TabBar(
            tabs: [
              Tab(
                text: context.tr('finance.revenue'),
                icon: const Icon(Icons.trending_up, size: 18),
              ),
              Tab(
                text: context.tr('finance.totalOutstanding'),
                icon: const Icon(Icons.warning_amber, size: 18),
              ),
              Tab(
                text: context.tr('finance.totalExemptions'),
                icon: const Icon(Icons.card_giftcard, size: 18),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RevenueReportPage(),
            OutstandingReportPage(),
            ExemptionsReportPage(),
          ],
        ),
      ),
    );
  }
}
