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
  static double get xl => 24.h;
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

/// 🔘 شريط إجراء سفلي ثابت
class _StickyActionBar extends StatelessWidget {
  final String submitLabel;
  final IconData submitIcon;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  const _StickyActionBar({
    required this.submitLabel,
    required this.submitIcon,
    required this.onSubmit,
    this.isSubmitting = false,
  });

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
                    : Icon(submitIcon, size: 18.sp),
                label: Text(
                  submitLabel,
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

/// 📁 صفحة إضافة طالب
class AddStudentPage extends StatelessWidget {
  const AddStudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StudentsBloc>(),
      child: const AddStudentView(),
    );
  }
}

class AddStudentView extends StatefulWidget {
  const AddStudentView({super.key});

  @override
  State<AddStudentView> createState() => _AddStudentViewState();
}

class _AddStudentViewState extends State<AddStudentView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _studentCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  String? _status = 'active';
  bool _isSubmitting = false;

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

  String _generateStudentCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'STU${timestamp.substring(timestamp.length - 6)}';
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

    final student = StudentEntity(
      studentCode: _studentCodeController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      status: _status ?? 'active',
      notes: _notesController.text.trim(),
    );

    setState(() => _isSubmitting = true);
    context.read<StudentsBloc>().add(CreateStudentEvent(student));
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
        appBar: AppBar(title: Text(context.tr('students.add'))),
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
                          labelText: '${context.tr('students.firstName')} *',
                          prefixIcon: Icon(Icons.person, size: 18),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'يرجى إدخال الاسم'
                            : null,
                      ),
                      SizedBox(height: _Gap.md),
                      TextFormField(
                        controller: _lastNameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: '${context.tr('students.lastName')} *',
                          prefixIcon: Icon(Icons.person, size: 18),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'يرجى إدخال اللقب'
                            : null,
                      ),
                      SizedBox(height: _Gap.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _studentCodeController,
                              decoration: InputDecoration(
                                labelText:
                                    '${context.tr('students.studentCode')} *',
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  size: 18,
                                ),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'مطلوب'
                                  : null,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _studentCodeController.text =
                                    _generateStudentCode();
                              });
                            },
                            icon: Icon(
                              Icons.refresh,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20.sp,
                            ),
                            tooltip: context.tr('students.generateCode'),
                          ),
                        ],
                      ),
                      SizedBox(height: _Gap.md),
                      InkWell(
                        onTap: _pickDateOfBirth,
                        borderRadius: BorderRadius.circular(10.r),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: context.tr('students.dateOfBirth'),
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              size: 18,
                            ),
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
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.tr('students.gender'),
                          prefixIcon: Icon(Icons.wc, size: 18),
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
          submitLabel: context.tr('students.add'),
          submitIcon: Icons.person_add,
          onSubmit: _submit,
          isSubmitting: _isSubmitting,
        ),
      ),
    );
  }
}
