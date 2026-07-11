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
      // Validate page 1 fields
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
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
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

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final result = await ref.read(authStateProvider.notifier).registerTrader(
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
    // Navigation handled by router
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
                _currentPage == 0
                    ? 'Basic Info'
                    : 'Account Setup',
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
            onPressed: _currentPage == 0 ? _nextPage : _handleRegister,
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
}