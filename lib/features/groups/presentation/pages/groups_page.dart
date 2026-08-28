import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 📁 صفحة الأفواج - نسخة مؤقتة

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأفواج'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64.sp,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(height: 16.h),
            Text(
              'قسم الأفواج قيد الإنشاء',
              style: TextStyle(fontSize: 16.sp, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
