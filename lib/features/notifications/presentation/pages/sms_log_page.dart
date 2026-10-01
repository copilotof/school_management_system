import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/database/app_database.dart';
import 'package:school_management_system/injection_container.dart';

class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 صفحة سجل الرسائل القصيرة
class SmsLogPage extends StatefulWidget {
  const SmsLogPage({super.key});

  @override
  State<SmsLogPage> createState() => _SmsLogPageState();
}

class _SmsLogPageState extends State<SmsLogPage> {
  List<SmsLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final db = getIt<AppDatabase>();
    final logs =
        await (db.select(db.smsLogs)..orderBy([
              (t) =>
                  OrderingTerm(expression: t.sentAt, mode: OrderingMode.desc),
            ]))
            .get();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الرسائل القصيرة'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sms_outlined,
                    size: 64.sp,
                    color: colors.onSurfaceVariant,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'لا توجد رسائل مرسلة',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(12.w),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final isSent = log.status == 'sent';
                final statusColor = isSent ? Colors.green : Colors.red;
                final statusIcon = isSent ? Icons.check_circle : Icons.error;
                final statusLabel = isSent ? 'تم الإرسال' : 'فشل';

                return Card(
                  margin: EdgeInsets.only(bottom: 6.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    side: BorderSide(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(statusIcon, size: 16.sp, color: statusColor),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                log.recipientName ?? log.phone,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          log.phone,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            log.body,
                            style: TextStyle(fontSize: 11.sp),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (log.errorMessage != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            'خطأ: ${log.errorMessage}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.red,
                            ),
                          ),
                        ],
                        SizedBox(height: 4.h),
                        Text(
                          DateFormat('yyyy/MM/dd HH:mm').format(log.sentAt),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
