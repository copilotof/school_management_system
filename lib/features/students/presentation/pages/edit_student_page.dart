import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/states/ui_state.dart';
import 'package:school_management_system/core/widgets/custom_date_picker.dart';
import 'package:school_management_system/features/students/domain/entities/student_entity.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_bloc.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_event.dart';
import 'package:school_management_system/features/students/presentation/bloc/students_state.dart';
import 'package:school_management_system/injection_container.dart';

import '../../../../core/utils/translation_extension.dart';

// ============================================================
// 🎨 ثوابت التصميم الموحدة
// ============================================================
class _Gap {
  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
}

const double _kRadius = 14;

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

class _FormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _FormCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(icon: icon, title: title),
          SizedBox(height: _Gap.md),
          child,
        ],
      ),
    );
  }
}

class _StickyActionBar extends StatelessWidget {
  final VoidCallback onSubmit;
  final bool isSubmitting;

  const _StickyActionBar({required this.onSubmit, this.isSubmitting = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
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
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kRadius),
                  ),
                ),
                child: Text(context.tr('common.cancel')),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.save, size: 18.sp),
                label: Text(
                  context.tr('students.saveChanges'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
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
    );
  }
}

/// 📁 صفحة تعديل طالب
class EditStudentPage extends StatelessWidget {
  final StudentEntity student;

  const EditStudentPage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StudentsBloc>(),
      child: EditStudentView(student: student),
    );
  }
}

class EditStudentView extends StatefulWidget {
  final StudentEntity student;

  const EditStudentView({super.key, required this.student});

  @override
  State<EditStudentView> createState() => _EditStudentViewState();
}

class _EditStudentViewState extends State<EditStudentView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _studentCodeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  DateTime? _dateOfBirth;
  String? _gender;
  String? _status;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.student.firstName,
    );
    _lastNameController = TextEditingController(text: widget.student.lastName);
    _studentCodeController = TextEditingController(
      text: widget.student.studentCode,
    );
    _phoneController = TextEditingController(text: widget.student.phone ?? '');
    _addressController = TextEditingController(
      text: widget.student.address ?? '',
    );
    _notesController = TextEditingController(text: widget.student.notes ?? '');
    _dateOfBirth = widget.student.dateOfBirth;
    _gender = widget.student.gender;
    _status = widget.student.status;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentCodeController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final updatedStudent = StudentEntity(
      id: widget.student.id,
      studentCode: _studentCodeController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      status: _status ?? 'active',
      notes: _notesController.text.trim(),
      createdAt: widget.student.createdAt,
      updatedAt: DateTime.now(),
    );

    setState(() => _isSubmitting = true);
    context.read<StudentsBloc>().add(UpdateStudentEvent(updatedStudent));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StudentsBloc, StudentsState>(
      listener: (context, state) {
        if (state.studentsState is Success && _isSubmitting) {
          Navigator.of(context).pop(true);
        }
        if (state.errorMessage != null) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(context.tr('students.edit'))),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FormCard(
                  icon: Icons.person_outline,
                  title: context.tr('students.basicInfo'),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.tr('students.firstName'),
                          prefixIcon: Icon(Icons.person, size: 18),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? context.tr('students.firstNameRequired')
                            : null,
                      ),
                      SizedBox(height: _Gap.md),
                      TextFormField(
                        controller: _lastNameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: '${context.tr('students.lastName')} *',
                          prefixIcon: const Icon(Icons.person, size: 18),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? context.tr('students.lastNameRequired')
                            : null,
                      ),
                      SizedBox(height: _Gap.md),
                      TextFormField(
                        controller: _studentCodeController,
                        decoration: InputDecoration(
                          labelText: context.tr('students.studentCode'),
                          prefixIcon: Icon(Icons.badge_outlined, size: 18),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? context.tr('students.studentCodeRequired')
                            : null,
                      ),
                      SizedBox(height: _Gap.md),
                      InkWell(
                        onTap: _pickDateOfBirth,
                        borderRadius: BorderRadius.circular(10.r),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: context.tr('students.dateOfBirth'),
                            prefixIcon: Icon(Icons.calendar_today, size: 18),
                            isDense: true,
                          ),
                          child: Text(
                            _dateOfBirth != null
                                ? DateFormat('yyyy/MM/dd').format(_dateOfBirth!)
                                : context.tr('students.selectDate'),
                            style: TextStyle(fontSize: 13.sp),
                          ),
                        ),
                      ),
                      SizedBox(height: _Gap.md),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.tr('students.gender'),
                          prefixIcon: const Icon(Icons.wc, size: 18),
                          isDense: true,
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
                    ],
                  ),
                ),
                SizedBox(height: _Gap.md),
                _FormCard(
                  icon: Icons.phone_outlined,
                  title: context.tr('students.contactInfo'),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: context.tr('students.phone'),
                          prefixIcon: Icon(Icons.phone, size: 18),
                          isDense: true,
                        ),
                      ),
                      SizedBox(height: _Gap.md),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: context.tr('students.address'),
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            size: 18,
                          ),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _Gap.md),
                _FormCard(
                  icon: Icons.info_outline,
                  title: context.tr('students.additionalInfo'),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.tr('students.status'),
                          prefixIcon: Icon(Icons.info, size: 18),
                          isDense: true,
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
                      SizedBox(height: _Gap.md),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: context.tr('students.notes'),
                          prefixIcon: Icon(Icons.notes, size: 18),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _StickyActionBar(
          onSubmit: _submit,
          isSubmitting: _isSubmitting,
        ),
      ),
    );
  }
}
