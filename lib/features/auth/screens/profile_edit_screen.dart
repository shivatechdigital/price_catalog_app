import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_button.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _businessController;
  late final TextEditingController _cityController;
  late final TextEditingController _gstController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: currentUser?.name ?? '');
    _phoneController = TextEditingController(text: currentUser?.phone ?? '');
    _businessController = TextEditingController(text: currentUser?.businessName ?? '');
    _cityController = TextEditingController(text: currentUser?.city ?? '');
    _gstController = TextEditingController(text: currentUser?.gstNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _businessController.dispose();
    _cityController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final result = await ref.read(authStateProvider.notifier).updateProfile(
          name: _nameController.text,
          phone: _phoneController.text,
          businessName: currentUser.isTrader
              ? _businessController.text
              : currentUser.businessName,
          city: currentUser.isTrader ? _cityController.text : currentUser.city,
          gstNumber:
              currentUser.isTrader ? _gstController.text : currentUser.gstNumber,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      CustomSnackbar.showSuccess(context, 'Profile updated successfully.');
      Navigator.pop(context);
    } else {
      CustomSnackbar.showError(context, result.errorMessage ?? 'Update failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isTrader = currentUser?.isTrader == true;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap(16.h),
                  Text(
                    'Update your profile details so we can keep your account current.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  Gap(24.h),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter your name',
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
                  if (isTrader) ...[
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
                    label: 'Save Changes',
                    isLoading: _isLoading,
                    gradient: isTrader
                        ? AppColors.traderGradient
                        : AppColors.adminGradient,
                    onPressed: _handleSave,
                  ),
                  Gap(24.h),
                ],
              ),
            ),
          ),
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
            if (keyboardType == TextInputType.phone && value.length < 8) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }
}
