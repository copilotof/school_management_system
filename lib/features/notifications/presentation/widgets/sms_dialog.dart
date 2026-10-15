import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_management_system/core/utils/translation_extension.dart';
import 'package:school_management_system/features/notifications/services/sms_service.dart';

// ============================================================
// 🎨 نظام تصميم محلي (خاص بهذا الملف) — Material 3
// ============================================================
class _Sp {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

class _Rad {
  static double get sheet => 22.r;
  static double get field => 12.r;
  static double get chip => 100.r;
}

/// 📁 حوار إرسال SMS
/// ⚠️ الإرسال يدوي فقط — يحتاج ضغط "إرسال"
class SmsDialog extends StatefulWidget {
  final List<SmsRecipient> recipients;
  final String initialMessage;
  final SmsService smsService;

  const SmsDialog({
    super.key,
    required this.recipients,
    required this.initialMessage,
    required this.smsService,
  });

  @override
  State<SmsDialog> createState() => _SmsDialogState();
}

class _SmsDialogState extends State<SmsDialog> {
  late TextEditingController _messageController;
  late Set<int> _selectedRecipientIds;
  bool _isSending = false;
  SmsProgress? _progress;

  bool get _allSelected =>
      _selectedRecipientIds.length == widget.recipients.length;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.initialMessage);
    // ✅ تحديد كل المستلمين افتراضياً
    _selectedRecipientIds = {
      for (int i = 0; i < widget.recipients.length; i++) i,
    };
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedRecipientIds.clear();
      } else {
        _selectedRecipientIds = {
          for (int i = 0; i < widget.recipients.length; i++) i,
        };
      }
    });
  }

  /// ✅ إرسال SMS (يدوي)
  Future<void> _sendSms() async {
    if (_selectedRecipientIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('prompts.selectRecipient'))),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('sms.emptyMessage'))),
      );
      return;
    }

    // تأكيد الإرسال
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Rad.sheet),
        ),
        icon: Icon(Icons.send_rounded, color: colors.primary),
        title: Text(context.tr('common.confirm')),
        content: Text(
          context.tr(
            'sms.confirmSend',
            params: {'count': '${_selectedRecipientIds.length}'},
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_Rad.field),
              ),
            ),
            child: Text(context.tr('sms.send')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSending = true;
      _progress = null;
    });

    final selectedRecipients = widget.recipients
        .where(
          (r) => _selectedRecipientIds.contains(widget.recipients.indexOf(r)),
        )
        .toList();

    // ✅ الإرسال (يدوي)
    await for (final progress in widget.smsService.sendBulkSms(
      recipients: selectedRecipients,
      body: _messageController.text,
    )) {
      if (mounted) {
        setState(() => _progress = progress);
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final messageLength = _messageController.text.characters.length;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_Rad.sheet),
      ),
      insetPadding: EdgeInsets.all(16.w),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500.w,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ====== العنوان (ثابت) ======
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 14.h),
              child: Row(
                children: [
                  Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sms_outlined,
                      size: 19.sp,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      context.tr('sms.sendTitle'),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _isSending
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.outlineVariant),

            // ====== المحتوى (قابل للتمرير) ======
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ====== شريط التقدم (عند الإرسال) ======
                    if (_isSending && _progress != null) ...[
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(_Rad.field),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.primary,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    '${context.tr('sms.sending')} ${_progress!.processed} / ${_progress!.total}',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(_progress!.percentage * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3.r),
                              child: LinearProgressIndicator(
                                value: _progress!.percentage,
                                minHeight: 6.h,
                                backgroundColor: colors.surfaceContainerHighest,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Row(
                              children: [
                                _StatBadge(
                                  icon: Icons.check_circle_outline,
                                  label: context.tr('sms.sent'),
                                  value: '${_progress!.sent}',
                                  color: colors.primary,
                                ),
                                SizedBox(width: 8.w),
                                _StatBadge(
                                  icon: Icons.error_outline,
                                  label: context.tr('sms.failed'),
                                  value: '${_progress!.failed}',
                                  color: colors.error,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: _Sp.md),
                    ],

                    // ====== المستلمون ======
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${context.tr('sms.recipients')} (${_selectedRecipientIds.length} / ${widget.recipients.length})',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _isSending ? null : _toggleSelectAll,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _allSelected
                                ? context.tr('common.deselectAll')
                                : context.tr('common.selectAll'),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _Sp.xs),
                    Container(
                      constraints: BoxConstraints(maxHeight: 180.h),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_Rad.field),
                        border: Border.all(
                          color: colors.outlineVariant.withOpacity(0.6),
                        ),
                      ),
                      // ✅ اللون على Material وليس على الـ Container، حتى يرسم
                      // ListTile خلفيته وتأثير اللمس بشكل صحيح فوقه.
                      child: Material(
                        color: colors.surfaceContainerLow,
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          itemCount: widget.recipients.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 14.w,
                            endIndent: 14.w,
                            color: colors.outlineVariant.withOpacity(0.4),
                          ),
                          itemBuilder: (context, index) {
                            final recipient = widget.recipients[index];
                            final isSelected = _selectedRecipientIds.contains(
                              index,
                            );
                            return CheckboxListTile(
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              shape: const RoundedRectangleBorder(),
                              value: isSelected,
                              onChanged: _isSending
                                  ? null
                                  : (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedRecipientIds.add(index);
                                        } else {
                                          _selectedRecipientIds.remove(index);
                                        }
                                      });
                                    },
                              title: Text(
                                recipient.name,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                recipient.phone,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: _Sp.md),

                    // ====== نص الرسالة ======
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('sms.message'),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          context.tr(
                            'sms.charCount',
                            params: {'count': '$messageLength'},
                          ),
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _Sp.sm),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      minLines: 3,
                      enabled: !_isSending,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(fontSize: 13.sp),
                      decoration: InputDecoration(
                        hintText: context.tr('sms.messagePlaceholder'),
                        filled: true,
                        fillColor: colors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_Rad.field),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ====== الأزرار (ثابتة أسفل) ======
            Divider(height: 1, color: colors.outlineVariant),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: _isSending
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          context.tr('sms.sending'),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46.h,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colors.outline),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    _Rad.field,
                                  ),
                                ),
                              ),
                              child: Text(context.tr('common.cancel')),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 46.h,
                            child: FilledButton.icon(
                              onPressed: _sendSms,
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                context.tr(
                                  'sms.sendCount',
                                  params: {
                                    'count': '${_selectedRecipientIds.length}',
                                  },
                                ),
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    _Rad.field,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📊 شارة إحصائية
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_Rad.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
