import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 📁 صفحة المالية - نسخة مؤقتة

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإدارة المالية'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payments_outlined,
              size: 64.sp,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(height: 16.h),
            Text(
              'قسم المالية قيد الإنشاء',
              style: TextStyle(fontSize: 16.sp, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
