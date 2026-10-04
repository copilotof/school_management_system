import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:school_management_system/features/students/domain/entities/student_entity.dart';

class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

/// 📁 نتيجة المسح
class QrScanResult {
  final Map<int, String> attendanceMap; // studentId -> status
  final bool saved;

  const QrScanResult({required this.attendanceMap, required this.saved});
}

/// 📁 صفحة المسح المتسلسل لـ QR
/// ✅ تُرجع: QrScanResult عند "إنهاء"
class QrScannerPage extends StatefulWidget {
  /// قائمة طلاب الفوج
  final List<StudentEntity> groupStudents;

  /// حالة الحضور الحالية (studentId -> status)
  final Map<int, String> initialAttendance;

  const QrScannerPage({
    super.key,
    required this.groupStudents,
    required this.initialAttendance,
  });

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  late MobileScannerController _controller;
  final Map<int, String> _attendanceMap = {}; // خريطة الطلاب المسجلين
  final Set<int> _scannedIds = {}; // الطلاب الذين تم مسحهم في هذه الجلسة
  bool _isProcessing = false;
  String? _lastScannedCode;
  DateTime _lastScanTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // ✅ نسخ الحضور المبدئي
    _attendanceMap.addAll(widget.initialAttendance);

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ✅ إجمالي الطلاب في الفوج
  int get _totalStudents => widget.groupStudents.length;

  /// ✅ عدد الذين تم مسحهم
  int get _scannedCount => _scannedIds.length;

  /// ✅ عدد الذين لديهم حالة حضور
  int get _attendedCount =>
      _attendanceMap.values.where((s) => s == 'present' || s == 'late').length;

  /// ✅ عند اكتشاف QR
  void _handleDetection(BarcodeCapture capture) {
    if (_isProcessing) return;

    // منع المسح السريع المتتالي
    final now = DateTime.now();
    if (now.difference(_lastScanTime).inMilliseconds < 800) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    // منع المسح المكرر لنفس الكود في وقت قصير
    if (_lastScannedCode == rawValue) return;
    _lastScannedCode = rawValue;
    _lastScanTime = now;

    // ✅ تحليل رمز QR
    String? studentCode;
    if (rawValue.contains('CODE:')) {
      final parts = rawValue.split('|');
      for (final part in parts) {
        if (part.startsWith('CODE:')) {
          studentCode = part.substring(5);
          break;
        }
      }
    } else {
      studentCode = rawValue;
    }

    if (studentCode == null || studentCode.isEmpty) {
      _showError('رمز غير صالح');
      return;
    }

    // ✅ البحث عن الطالب
    final student = widget.groupStudents
        .where((s) => s.studentCode == studentCode)
        .firstOrNull;

    if (student == null) {
      _showError('الطالب غير موجود في هذا الفوج: $studentCode');
      return;
    }

    // ✅ منع التكرار
    if (_scannedIds.contains(student.id)) {
      _showWarning('${student.fullName} مُسجّل مسبقاً');
      return;
    }

    // ✅ تسجيل الحضور
    setState(() {
      _attendanceMap[student.id!] = 'present';
      _scannedIds.add(student.id!);
    });

    // ✅ صوت + اهتزاز
    _feedback();

    // ✅ عرض رسالة نجاح سريعة
    _showScanSuccess(student.fullName);
  }

  /// ✅ صوت + اهتزاز
  void _feedback() {
    // اهتزاز
    HapticFeedback.mediumImpact();
    // صوت نظام
    SystemSound.play(SystemSoundType.click);
  }

  /// ✅ عرض SnackBar نجاح
  void _showScanSuccess(String studentName) {
    final colors = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 800),
        backgroundColor: colors.secondary,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'تم: $studentName',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ عرض SnackBar خطأ
  void _showError(String message) {
    final colors = Theme.of(context).colorScheme;

    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        backgroundColor: colors.error,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ عرض SnackBar تحذير
  void _showWarning(String message) {
    final colors = Theme.of(context).colorScheme;

    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        backgroundColor: colors.tertiary,
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white, size: 20),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ إنهاء المسح
  void _finish() {
    Navigator.of(
      context,
    ).pop(QrScanResult(attendanceMap: _attendanceMap, saved: true));
  }

  /// ✅ إلغاء
  void _cancel() {
    // تأكيد الإلغاء إذا كان هناك مسحات
    if (_scannedIds.isNotEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('إلغاء المسح'),
          content: Text(
            'تم مسح ${_scannedIds.length} طالب. هل تريد إلغاء كل المسحات؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('متابعة المسح'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(
                  QrScanResult(
                    attendanceMap: widget.initialAttendance,
                    saved: false,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop(
        QrScanResult(attendanceMap: widget.initialAttendance, saved: false),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مسح الحضور'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'إلغاء',
          onPressed: _cancel,
        ),
        actions: [
          // الفلاش
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'الفلاش',
            onPressed: () => _controller.toggleTorch(),
          ),
          // تبديل الكاميرا
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'تبديل الكاميرا',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ====== الكاميرا ======
          SizedBox(
            height: 300.h,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _handleDetection,
                ),
                _ScannerOverlay(colors: colors),
                // عرض التقدم
                Positioned(
                  top: 16.h,
                  left: 16.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: colors.secondary,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '$_scannedCount / $_totalStudents',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ====== شريط التقدم ======
          LinearProgressIndicator(
            value: _totalStudents > 0 ? _scannedCount / _totalStudents : 0,
            minHeight: 4.h,
            backgroundColor: colors.surfaceContainerHighest,
          ),

          // ====== قائمة الطلاب ======
          Expanded(child: _buildStudentsList(colors)),

          // ====== الشريط السفلي ======
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancel,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('إلغاء'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(0, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_kRadius),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _finish,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        'إنهاء المسح ($_scannedCount)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(0, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_kRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ قائمة الطلاب
  Widget _buildStudentsList(ColorScheme colors) {
    // ترتيب: المسحون أولاً، ثم الباقون
    final sortedStudents = [...widget.groupStudents];
    sortedStudents.sort((a, b) {
      final aScanned = _scannedIds.contains(a.id);
      final bScanned = _scannedIds.contains(b.id);
      if (aScanned && !bScanned) return -1;
      if (!aScanned && bScanned) return 1;
      return a.fullName.compareTo(b.fullName);
    });

    return ListView.builder(
      padding: EdgeInsets.all(12.w),
      itemCount: sortedStudents.length,
      itemBuilder: (context, index) {
        final student = sortedStudents[index];
        final isScanned = _scannedIds.contains(student.id);
        final currentStatus = _attendanceMap[student.id];

        return _StudentScanTile(
          student: student,
          isScanned: isScanned,
          currentStatus: currentStatus,
        );
      },
    );
  }
}

/// 📁 بطاقة طالب في قائمة المسح
class _StudentScanTile extends StatelessWidget {
  final StudentEntity student;
  final bool isScanned;
  final String? currentStatus;

  const _StudentScanTile({
    required this.student,
    required this.isScanned,
    this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // لون الحالة
    final Color color;
    final IconData icon;
    final String label;

    if (isScanned) {
      color = colors.secondary;
      icon = Icons.check_circle;
      label = 'تم';
    } else if (currentStatus != null && currentStatus != 'pending') {
      color = Colors.blue;
      icon = Icons.info;
      label = _statusLabel(currentStatus!);
    } else {
      color = colors.onSurfaceVariant;
      icon = Icons.pending_outlined;
      label = 'في الانتظار';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isScanned ? color.withOpacity(0.08) : colors.surface,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isScanned ? color.withOpacity(0.5) : colors.outlineVariant,
          width: isScanned ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: isScanned
                ? color.withOpacity(0.2)
                : colors.primaryContainer,
            child: Text(
              student.firstName.isNotEmpty
                  ? student.firstName.substring(0, 1)
                  : '؟',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: isScanned ? color : colors.onPrimaryContainer,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isScanned ? color : colors.onSurface,
                  ),
                ),
                Text(
                  student.studentCode,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'present':
        return 'حاضر';
      case 'absent':
        return 'غائب';
      case 'late':
        return 'متأخر';
      default:
        return status;
    }
  }
}

/// 📁 إطار المسح
class _ScannerOverlay extends StatelessWidget {
  final ColorScheme colors;
  const _ScannerOverlay({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200.w,
        height: 200.h,
        decoration: BoxDecoration(
          border: Border.all(color: colors.primary, width: 3),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: _Corner(color: colors.primary, x: -1, y: -1),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: _Corner(color: colors.primary, x: 1, y: -1),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: _Corner(color: colors.primary, x: -1, y: 1),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: _Corner(color: colors.primary, x: 1, y: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final Color color;
  final int x;
  final int y;

  const _Corner({required this.color, required this.x, required this.y});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28.w,
      height: 28.h,
      decoration: BoxDecoration(
        border: Border(
          top: y == -1 ? BorderSide(color: color, width: 4) : BorderSide.none,
          bottom: y == 1 ? BorderSide(color: color, width: 4) : BorderSide.none,
          left: x == -1 ? BorderSide(color: color, width: 4) : BorderSide.none,
          right: x == 1 ? BorderSide(color: color, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}
