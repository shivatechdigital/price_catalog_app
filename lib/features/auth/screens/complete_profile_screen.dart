import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/user_model.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_button.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessController = TextEditingController();
  final _cityController = TextEditingController();
  final _gstController = TextEditingController();

  UserRole _selectedRole = UserRole.admin;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _businessController.dispose();
    _cityController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final result = await ref.read(authStateProvider.notifier).completeProfile(
          name: _nameController.text,
          phone: _phoneController.text,
          role: _selectedRole,
          businessName: _businessController.text.isNotEmpty
              ? _businessController.text
              : null,
          city: _cityController.text.isNotEmpty ? _cityController.text : null,
          gstNumber: _gstController.text.isNotEmpty ? _gstController.text : null,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      CustomSnackbar.showError(context, result.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Gap(12.h),
                    Text(
                      'Your account needs a profile document before you can continue. Please complete the form below.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    Gap(28.h),
                    Text(
                      'Account Type',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Gap(12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRoleOption(
                            role: UserRole.admin,
                            label: 'Admin',
                            description: 'Manage products and approvals.',
                          ),
                        ),
                        Gap(12.w),
                        Expanded(
                          child: _buildRoleOption(
                            role: UserRole.trader,
                            label: 'Trader',
                            description: 'Submit prices and browse catalog.',
                          ),
                        ),
                      ],
                    ),
                    Gap(24.h),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter full name',
                      icon: Iconsax.user,
                      keyboardType: TextInputType.name,
                    ),
                    Gap(16.h),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter phone number',
                      icon: Iconsax.call,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 10,
                    ),
                    if (_selectedRole == UserRole.trader) ...[
                      Gap(16.h),
                      _buildTextField(
                        controller: _businessController,
                        label: 'Business Name',
                        hint: 'Enter business name',
                        icon: Iconsax.export,
                        keyboardType: TextInputType.text,
                      ),
                      Gap(16.h),
                      _buildTextField(
                        controller: _cityController,
                        label: 'City',
                        hint: 'Enter city',
                        icon: Iconsax.location,
                        keyboardType: TextInputType.text,
                      ),
                      Gap(16.h),
                      _buildTextField(
                        controller: _gstController,
                        label: 'GST Number',
                        hint: 'Enter GST number',
                        icon: Iconsax.document,
                        keyboardType: TextInputType.text,
                      ),
                    ],
                    Gap(32.h),
                    CustomButton(
                      label: 'Complete Profile',
                      isLoading: _isLoading,
                      gradient: _selectedRole == UserRole.admin
                          ? AppColors.adminGradient
                          : AppColors.traderGradient,
                      onPressed: _handleCompleteProfile,
                    ),
                    Gap(18.h),
                    Text(
                      'If you are an admin account, choose Admin. Traders will be reviewed before approval.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required UserRole role,
    required String label,
    required String description,
  }) {
    final isSelected = _selectedRole == role;
    final color = role == UserRole.admin ? AppColors.adminPrimary : AppColors.traderPrimary;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(20) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Gap(8.h),
            Text(
              description,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: Icon(icon, size: 20.sp, color: AppColors.textHint),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label'.toLowerCase();
            }
            if (keyboardType == TextInputType.emailAddress &&
                !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            if (maxLength != null && value.length < maxLength) {
              return 'Please enter a valid $label';
            }
            return null;
          },
        ),
      ],
    );
  }
}
