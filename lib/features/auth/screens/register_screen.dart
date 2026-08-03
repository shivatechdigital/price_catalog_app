import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_button.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  int _currentPage = 0;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // NEXT PAGE
  // ═══════════════════════════════════════
  void _nextPage() {
    if (_currentPage == 0) {
      if (_nameController.text.isEmpty ||
          _phoneController.text.isEmpty) {
        CustomSnackbar.showWarning(
          context,
          'Please fill all required fields',
        );
        return;
      }
      if (_phoneController.text.length < 10) {
        CustomSnackbar.showWarning(
          context,
          'Please enter valid phone number',
        );
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }
    // Page 1 — validate and register directly
    if (_currentPage == 1) {
      if (!_formKey.currentState!.validate()) return;
      if (!_agreeToTerms) {
        CustomSnackbar.showWarning(
          context,
          'Please agree to terms and conditions',
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        CustomSnackbar.showError(context, 'Passwords do not match');
        return;
      }
      _handleRegister();
    }
  }

  // ═══════════════════════════════════════
  // PREVIOUS PAGE
  // ═══════════════════════════════════════
  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ═══════════════════════════════════════
  // REGISTER ACTION
  // ═══════════════════════════════════════
  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final result = await ref
        .read(authStateProvider.notifier)
        .registerTrader(
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          password: _passwordController.text,
          city: _cityController.text,
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
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ═══════════════════════════════════════
                // TOP BAR
                // ═══════════════════════════════════════
                _buildTopBar(),

                // ═══════════════════════════════════════
                // PROGRESS INDICATOR
                // ═══════════════════════════════════════
                _buildProgressIndicator(),

                Gap(8.h),

                // ═══════════════════════════════════════
                // PAGE VIEW
                // ═══════════════════════════════════════
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: [
                      _buildPage1(),
                      _buildPage2(),
                    ],
                  ),
                ),

                // ═══════════════════════════════════════
                // BOTTOM BUTTONS
                // ═══════════════════════════════════════
                _buildBottomButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════
  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_currentPage == 0) {
                context.pop();
              } else {
                _previousPage();
              }
            },
            icon: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18.sp,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Create Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 56.w),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // PROGRESS INDICATOR
  // ═══════════════════════════════════════
  Widget _buildProgressIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Row(
            children: List.generate(2, (index) {
              final isActive = index <= _currentPage;
              final isCurrent = index == _currentPage;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.adminPrimary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.adminPrimary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          Gap(8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentPage + 1} of 2',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _currentPage == 0 ? 'Basic Info' : 'Account Setup',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.adminPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // PAGE 1 - Business Info
  // ═══════════════════════════════════════
  Widget _buildPage1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Gap(24.h),

          // Header
          Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn().slideY(begin: 0.3, end: 0),

          Gap(6.h),

          Text(
            'Tell us a bit about yourself',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms),

          Gap(28.h),

          // Full Name
          _buildLabel('Full Name *'),
          Gap(8.h),
          _buildTextField(
            controller: _nameController,
            hint: 'Enter your full name',
            icon: Iconsax.user,
            inputAction: TextInputAction.next,
          ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),

          Gap(16.h),

          // Phone
          _buildLabel('Phone Number *'),
          Gap(8.h),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Enter 10 digit number',
              counterText: '',
              prefixIcon: Icon(
                Iconsax.call,
                size: 20.sp,
                color: AppColors.textHint,
              ),
              prefixText: '+91  ',
              prefixStyle: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),

          Gap(16.h),

          // City
          _buildLabel('City'),
          Gap(8.h),
          _buildTextField(
            controller: _cityController,
            hint: 'Enter your city',
            icon: Iconsax.location,
            inputAction: TextInputAction.done,
            isRequired: false,
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

          Gap(32.h),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // PAGE 2 - Account Setup
  // ═══════════════════════════════════════
  Widget _buildPage2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Gap(24.h),

          // Header
          Text(
            'Account Setup',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn().slideY(begin: 0.3, end: 0),

          Gap(6.h),

          Text(
            'Create your login credentials',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms),

          Gap(28.h),

          // Email
          _buildLabel('Email Address *'),
          Gap(8.h),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              prefixIcon: Icon(
                Iconsax.sms,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter valid email';
              }
              return null;
            },
          ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),

          Gap(16.h),

          // Password
          _buildLabel('Password *'),
          Gap(8.h),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Min 6 characters',
              prefixIcon: Icon(
                Iconsax.lock,
                size: 20.sp,
                color: AppColors.textHint,
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
                icon: Icon(
                  _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                  size: 20.sp,
                  color: AppColors.textHint,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

          Gap(16.h),

          // Confirm Password
          _buildLabel('Confirm Password *'),
          Gap(8.h),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Re-enter your password',
              prefixIcon: Icon(
                Iconsax.lock_1,
                size: 20.sp,
                color: AppColors.textHint,
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                icon: Icon(
                  _obscureConfirmPassword
                      ? Iconsax.eye_slash
                      : Iconsax.eye,
                  size: 20.sp,
                  color: AppColors.textHint,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),

          Gap(24.h),

          // Terms & Conditions
          _buildTermsCheckbox()
              .animate()
              .fadeIn(delay: 300.ms),

          Gap(16.h),

          // Info Box
          _buildInfoBox()
              .animate()
              .fadeIn(delay: 350.ms),

          Gap(32.h),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // TERMS CHECKBOX
  // ═══════════════════════════════════════
  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22.w,
            height: 22.w,
            child: Checkbox(
              value: _agreeToTerms,
              onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
              activeColor: AppColors.adminPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          Gap(10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: TextStyle(
                      color: AppColors.adminPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppColors.adminPrimary,
                      fontWeight: FontWeight.w600,
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

  // ═══════════════════════════════════════
  // INFO BOX
  // ═══════════════════════════════════════
  Widget _buildInfoBox() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.adminPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.adminPrimary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.info_circle,
            size: 20.sp,
            color: AppColors.adminPrimary,
          ),
          Gap(12.w),
          Expanded(
            child: Text(
              'Your account needs admin approval before you can login. '
              'You will be notified once approved.',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.adminPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // BOTTOM BUTTONS
  // ═══════════════════════════════════════
  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Action Button
          CustomButton(
            label: _currentPage == 0 ? 'Continue' : 'Create Account',
            isLoading: _isLoading,
            gradient: AppColors.adminGradient,
            prefixIcon: _currentPage == 0
                ? Icons.arrow_forward_rounded
                : Iconsax.user_add,
            onPressed: _nextPage,
          ),

          Gap(16.h),

          // Login Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.adminPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════
  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputAction inputAction = TextInputAction.next,
    bool isRequired = true,
    bool isCapitalized = false,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: inputAction,
      textCapitalization: isCapitalized
          ? TextCapitalization.characters
          : TextCapitalization.words,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: 20.sp,
          color: AppColors.textHint,
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
    );
  }

  // ═══════════════════════════════════════
  // PAGE 3 - DOCUMENT UPLOAD
  // ═══════════════════════════════════════
  Widget _buildPage3() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Gap(24.h),

          Text(
            'Document Verification',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn().slideY(begin: 0.3, end: 0),

          Gap(6.h),

          Text(
            'Upload front & back of your ID (Aadhar/PAN/GST)',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms),

          Gap(28.h),

          // Front Image
          _buildLabel('Document Front Side *'),
          Gap(10.h),
          _buildDocImagePicker(
            image: _frontDocImage,
            label: 'Front Side',
            icon: Iconsax.card,
            onPick: () => _pickDocImage(isFront: true),
          ).animate().fadeIn(delay: 150.ms),

          Gap(20.h),

          // Back Image
          _buildLabel('Document Back Side *'),
          Gap(10.h),
          _buildDocImagePicker(
            image: _backDocImage,
            label: 'Back Side',
            icon: Iconsax.card_slash,
            onPick: () => _pickDocImage(isFront: false),
          ).animate().fadeIn(delay: 200.ms),

          Gap(20.h),

          // Info box
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.adminPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.adminPrimary.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Iconsax.shield_tick,
                  size: 18.sp,
                  color: AppColors.adminPrimary,
                ),
                Gap(10.w),
                Expanded(
                  child: Text(
                    'Your documents are encrypted and only visible to admin for verification.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.adminPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms),

          Gap(32.h),
        ],
      ),
    );
  }

  Widget _buildDocImagePicker({
    required File? image,
    required String label,
    required IconData icon,
    required VoidCallback onPick,
  }) {
    return GestureDetector(
      onTap: onPick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 160.h,
        decoration: BoxDecoration(
          color: image != null
              ? Colors.transparent
              : AppColors.background,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: image != null
                ? AppColors.adminPrimary
                : AppColors.border,
            width: image != null ? 2 : 1.5,
          ),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(image, fit: BoxFit.cover),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.adminPrimary,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'Tap to change',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 36.sp,
                    color: AppColors.textHint,
                  ),
                  Gap(10.h),
                  Text(
                    'Tap to upload $label',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Gap(4.h),
                  Text(
                    'Camera or Gallery',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _pickDocImage({required bool isFront}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            Gap(16.h),
            Text(
              isFront ? 'Upload Front Side' : 'Upload Back Side',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Gap(20.h),
            Row(
              children: [
                Expanded(
                  child: _pickOption(
                    icon: Iconsax.camera,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickAndCrop(
                        source: ImageSource.camera,
                        isFront: isFront,
                      );
                    },
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: _pickOption(
                    icon: Iconsax.gallery,
                    label: 'Gallery',
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickAndCrop(
                        source: ImageSource.gallery,
                        isFront: isFront,
                      );
                    },
                  ),
                ),
              ],
            ),
            Gap(20.h),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndCrop({
    required ImageSource source,
    required bool isFront,
  }) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
    );
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: isFront ? 'Crop Front Side' : 'Crop Back Side',
          toolbarColor: AppColors.adminPrimary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.adminPrimary,
          initAspectRatio: CropAspectRatioPreset.ratio16x9,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: isFront ? 'Crop Front Side' : 'Crop Back Side',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
        ),
      ],
    );

    if (cropped != null && mounted) {
      setState(() {
        if (isFront) {
          _frontDocImage = File(cropped.path);
        } else {
          _backDocImage = File(cropped.path);
        }
      });
    }
  }

  Widget _pickOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28.sp, color: AppColors.adminPrimary),
            Gap(8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}