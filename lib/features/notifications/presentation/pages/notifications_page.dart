import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/widgets/confirm_dialog.dart';
import 'package:school_management_system/features/notifications/domain/entities/notification_entity.dart';
import 'package:school_management_system/features/notifications/presentation/bloc/notification_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../injection_container.dart';
import '../../services/sms_service.dart';
import '../widgets/sms_dialog.dart';

// ============================================================
// 🎨 نظام تصميم محلي (خاص بهذا الملف) — Material 3
// ============================================================
class _Sp {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
  static double get xl => 24.h;
}

class _Rad {
  static double get card => 16.r;
  static double get chip => 100.r;
  static double get sheet => 24.r;
}

/// 📁 صفحة الإشعارات
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationBloc>().add(FetchNotifications());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const NotificationsView();
  }
}

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'تعليم الكل كمقروء',
            onPressed: () {
              context.read<NotificationBloc>().add(MarkAllAsReadEvent());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  content: const Text('تم تعليم الكل كمقروء'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'حذف الكل',
            onPressed: () => _confirmDeleteAll(context),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          return switch (state.notificationsState) {
            Initial() => const SizedBox.shrink(),
            Loading() => const Center(child: CircularProgressIndicator()),
            Empty() => const _EmptyState(),
            Error(message: final msg) => _ErrorState(message: msg),
            Success(data: final notifications) => _NotificationsList(
              notifications: notifications,
            ),
          };
        },
      ),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'حذف كل الإشعارات',
      message: 'هل أنت متأكد من حذف جميع الإشعارات؟',
    );
    if (confirmed && context.mounted) {
      context.read<NotificationBloc>().add(DeleteAllNotificationsEvent());
    }
  }
}

/// 📋 قائمة الإشعارات مع شريط عدّاد "غير مقروء" أعلى القائمة
class _NotificationsList extends StatelessWidget {
  final List<NotificationEntity> notifications;
  const _NotificationsList({required this.notifications});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 16.h),
      itemCount: notifications.length + (unreadCount > 0 ? 1 : 0),
      separatorBuilder: (_, __) => SizedBox(height: _Sp.sm),
      itemBuilder: (context, index) {
        if (unreadCount > 0) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: _Sp.xs),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(_Rad.chip),
                    ),
                    child: Text(
                      '$unreadCount غير مقروء',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return _NotificationCard(notification: notifications[index - 1]);
        }
        return _NotificationCard(notification: notifications[index]);
      },
    );
  }
}

/// 📁 بطاقة إشعار — قابلة للسحب للحذف، بشريط تمييز جانبي لغير المقروء
class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // ✅ لون وأيقونة حسب النوع
    final (typeColor, typeIcon) = switch (notification.type) {
      'attendance' => (colors.error, Icons.event_busy_outlined),
      'payment' => (colors.primary, Icons.payments_outlined),
      'session' => (colors.tertiary, Icons.event_outlined),
      _ => (colors.secondary, Icons.info_outline),
    };

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(_Rad.card),
        ),
        child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        return await ConfirmDialog.show(
          context: context,
          title: 'حذف الإشعار',
          message: 'هل تريد حذف هذا الإشعار؟',
        );
      },
      onDismissed: (_) {
        context.read<NotificationBloc>().add(
          DeleteNotificationEvent(notification.id!),
        );
      },
      child: Material(
        color: notification.isRead
            ? colors.surface
            : typeColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(_Rad.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(_Rad.card),
          onTap: () {
            if (!notification.isRead) {
              context.read<NotificationBloc>().add(
                MarkAsReadEvent(notification.id!),
              );
            }
            _showDetails(context, notification, typeColor, typeIcon);
          },
          // ✅ ضغط مطول: إرسال SMS
          onLongPress: () {
            if (notification.type == 'attendance' ||
                notification.type == 'payment') {
              _showSmsDialog(context, notification);
            }
          },

          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_Rad.card),
              border: Border.all(
                color: notification.isRead
                    ? colors.outlineVariant.withOpacity(0.4)
                    : typeColor.withOpacity(0.3),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ====== شريط تمييز جانبي لغير المقروء ======
                  if (!notification.isRead)
                    Container(
                      width: 4.w,
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(_Rad.card),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الأيقونة
                          Container(
                            width: 40.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              typeIcon,
                              size: 20.sp,
                              color: typeColor,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          // المحتوى
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: TextStyle(
                                          fontSize: 13.5.sp,
                                          fontWeight: notification.isRead
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!notification.isRead) ...[
                                      SizedBox(width: 6.w),
                                      Container(
                                        width: 7.w,
                                        height: 7.h,
                                        decoration: BoxDecoration(
                                          color: typeColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  notification.body,
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    color: colors.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 11.sp,
                                      color: colors.onSurfaceVariant,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      _formatDate(notification.createdAt),
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),

                                    const Spacer(),
                                    // ✅ تلميح: ضغط مطول للإجراءات
                                    if (notification.type == 'attendance' ||
                                        notification.type == 'payment')
                                      Padding(
                                        padding: EdgeInsets.only(top: 4.h),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.touch_app_outlined,
                                              size: 10.sp,
                                              color: colors.onSurfaceVariant
                                                  .withOpacity(0.6),
                                            ),
                                            SizedBox(width: 4.w),
                                            Text(
                                              'اضغط مطولاً لإرسال رسالة قصيرة',
                                              style: TextStyle(
                                                fontSize: 9.sp,
                                                color: colors.onSurfaceVariant
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const Spacer(),
                                    // شارة النوع
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 7.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: typeColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          _Rad.chip,
                                        ),
                                      ),
                                      child: Text(
                                        notification.typeLabel,
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w600,
                                          color: typeColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSmsDialog(
    BuildContext context,
    NotificationEntity notification,
  ) async {
    final smsService = getIt<SmsService>();

    // ✅ جلب رقم هاتف ولي الأمر (student.phone)
    final db = getIt<AppDatabase>();
    String? phone;
    String? studentName;

    if (notification.recipientId != null) {
      final student =
          await (db.select(db.students)
                ..where((t) => t.id.equals(notification.recipientId!)))
              .getSingleOrNull();

      if (student != null) {
        phone = student.phone;
        studentName = '${student.firstName} ${student.lastName}'.trim();
      }
    }

    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد رقم هاتف لهذا الطالب')),
      );
      return;
    }

    final recipient = SmsRecipient(
      id: notification.recipientId,
      name: studentName ?? notification.title,
      phone: phone,
    );

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (_) => SmsDialog(
        recipients: [recipient],
        initialMessage: notification.body,
        smsService: smsService,
      ),
    );
  }

  /// ✅ تنسيق التاريخ (منذ ...)
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return DateFormat('yyyy/MM/dd').format(date);
  }

  /// ✅ نافذة التفاصيل — بنمط Material 3 (شكل مدوّر، أزرار مميزة)
  void _showDetails(
    BuildContext context,
    NotificationEntity notification,
    Color typeColor,
    IconData typeIcon,
  ) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Rad.sheet),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 20.sp),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _Sp.md),
              Text(
                notification.body,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.5,
                  color: colors.onSurface,
                ),
              ),
              SizedBox(height: _Sp.md),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 12.sp,
                    color: colors.onSurfaceVariant,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: _Sp.lg),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.read<NotificationBloc>().add(
                          DeleteNotificationEvent(notification.id!),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colors.error,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: const Text('حذف'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text('إغلاق'),
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

/// 📁 حالة فارغة
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(22.w),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 46.sp,
              color: colors.primary,
            ),
          ),
          SizedBox(height: _Sp.md),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'ستظهر هنا كل التنبيهات الجديدة أوّلاً بأول',
            style: TextStyle(fontSize: 11.5.sp, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 📁 حالة الخطأ
class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: colors.errorContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40.sp,
                color: colors.error,
              ),
            ),
            SizedBox(height: _Sp.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: _Sp.lg),
            FilledButton.tonalIcon(
              onPressed: () {
                context.read<NotificationBloc>().add(FetchNotifications());
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('إعادة المحاولة'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
