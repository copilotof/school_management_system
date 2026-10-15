import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:school_management_system/core/utils/responsive.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/core/widgets/custom_date_picker.dart';

import '../../../../core/utils/translation_extension.dart';

/// 📁 نموذج الطالب المشترك
/// يستخدم في صفحتي الإضافة والتعديل

class StudentForm extends StatefulWidget {
  final StudentEntity? initialStudent;
  final Function(StudentEntity) onSubmit;
  final bool isLoading;

  const StudentForm({
    super.key,
    this.initialStudent,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _studentCodeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  // قيم الحقول
  DateTime? _dateOfBirth;
  String? _gender;
  String? _status;

  @override
  void initState() {
    super.initState();
    final student = widget.initialStudent;
    _firstNameController = TextEditingController(
      text: student?.firstName ?? '',
    );
    _lastNameController = TextEditingController(text: student?.lastName ?? '');
    _studentCodeController = TextEditingController(
      text: student?.studentCode ?? '',
    );
    _phoneController = TextEditingController(text: student?.phone ?? '');
    _addressController = TextEditingController(text: student?.address ?? '');
    _notesController = TextEditingController(text: student?.notes ?? '');
    _dateOfBirth = student?.dateOfBirth;
    _gender = student?.gender;
    _status = student?.status ?? 'active';
  }

  @override
  void dispose() {
    // ✅ التخلص الصحيح من الموارد
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentCodeController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// اختيار تاريخ الميلاد
  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await CustomDatePicker.showBottomSheet(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 10, 1, 1),
      minDate: DateTime(now.year - 30),
      maxDate: DateTime(now.year - 3),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  /// توليد رقم طالب تلقائي
  String _generateStudentCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'STU${timestamp.substring(timestamp.length - 6)}';
  }

  /// حفظ النموذج
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final student = StudentEntity(
      id: widget.initialStudent?.id,
      studentCode: _studentCodeController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      status: _status ?? 'active',
      notes: _notesController.text.trim(),
      createdAt: widget.initialStudent?.createdAt,
      updatedAt: DateTime.now(),
    );

    widget.onSubmit(student);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: context.smartPadding(mobile: 16, tablet: 24, desktop: 32),
        children: [
          // ====== المعلومات الأساسية ======
          _buildSectionTitle(context, context.tr('students.personalInfo')),
          SizedBox(height: 12.h),

          // الاسم الأول
          TextFormField(
            controller: _firstNameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: '${context.tr('students.firstName')} *',
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.tr('students.firstNameRequired');
              }
              return null;
            },
          ),
          SizedBox(height: 12.h),

          // اللقب
          TextFormField(
            controller: _lastNameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: '${context.tr('students.lastName')} *',
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.tr('students.lastNameRequired');
              }
              return null;
            },
          ),
          SizedBox(height: 12.h),

          // رقم الطالب مع زر توليد
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _studentCodeController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '${context.tr('students.studentCode')} *',
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.tr('students.studentCodeRequired');
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: context.tr('students.generateCode'),
                onPressed: () {
                  setState(() {
                    _studentCodeController.text = _generateStudentCode();
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // تاريخ الميلاد
          InkWell(
            onTap: _pickDateOfBirth,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: context.tr('students.dateOfBirth'),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(
                _dateOfBirth != null
                    ? DateFormat('yyyy/MM/dd').format(_dateOfBirth!)
                    : context.tr('students.selectBirthDate'),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: _dateOfBirth != null
                      ? colors.onSurface
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // الجنس
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: InputDecoration(
              labelText: context.tr('students.gender'),
              prefixIcon: const Icon(Icons.wc),
            ),
            items: [
              DropdownMenuItem(
                value: 'male',
                child: Text(context.tr('students.male')),
              ),
              DropdownMenuItem(
                value: 'female',
                child: Text(context.tr('students.female')),
              ),
            ],
            onChanged: (value) => setState(() => _gender = value),
          ),
          SizedBox(height: 20.h),

          // ====== معلومات الاتصال ======
          _buildSectionTitle(context, context.tr('students.contactInfo')),
          SizedBox(height: 12.h),

          // الهاتف
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: context.tr('students.phone'),
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length < 8) {
                return context.tr('students.phoneInvalid');
              }
              return null;
            },
          ),
          SizedBox(height: 12.h),

          // العنوان
          TextFormField(
            controller: _addressController,
            textInputAction: TextInputAction.next,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: context.tr('students.address'),
              prefixIcon: const Icon(Icons.location_on_outlined),
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: 20.h),

          // ====== معلومات إضافية ======
          _buildSectionTitle(context, context.tr('students.additionalInfo')),
          SizedBox(height: 12.h),

          // الحالة
          DropdownButtonFormField<String>(
            value: _status,
            decoration: InputDecoration(
              labelText: context.tr('students.status'),
              prefixIcon: const Icon(Icons.info_outline),
            ),
            items: [
              DropdownMenuItem(
                value: 'active',
                child: Text(context.tr('students.active')),
              ),
              DropdownMenuItem(
                value: 'inactive',
                child: Text(context.tr('students.inactive')),
              ),
              DropdownMenuItem(
                value: 'withdrawn',
                child: Text(context.tr('students.withdrawn')),
              ),
            ],
            onChanged: (value) => setState(() => _status = value),
          ),
          SizedBox(height: 12.h),

          // ملاحظات
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.tr('students.notes'),
              prefixIcon: const Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: 24.h),

          // ====== أزرار ======
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isLoading ? null : _submit,
                  child: widget.isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.initialStudent == null
                              ? context.tr('students.add')
                              : context.tr('students.saveChanges'),
                        ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(context.tr('common.cancel')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء عنوان قسم
  Widget _buildSectionTitle(BuildContext context, String title) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
      ],
    );
  }
}
