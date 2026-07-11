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
import 'package:price_catalog_app/router/app_router.dart';
import 'package:price_catalog_app/shared/widgets/custom_button.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // LOGIN ACTION
  // ═══════════════════════════════════════
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final result = await ref.read(authStateProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      CustomSnackbar.showError(context, result.errorMessage!);
    }
    // Navigation handled by router redirect
  }

  // ═══════════════════════════════════════
  // FORGOT PASSWORD
  // ═══════════════════════════════════════
  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      CustomSnackbar.showWarning(
        context,
        'Please enter your email address first.',
      );
      return;
    }

    final result = await ref
        .read(authStateProvider.notifier)
        .forgotPassword(_emailController.text);

    if (!mounted) return;

    if (result.isSuccess) {
      CustomSnackbar.showSuccess(
        context,
        'Password reset email sent! Check your inbox.',
      );
    } else {
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Gap(40.h),

                    // ═══════════════════════════════════════
                    // HEADER
                    // ═══════════════════════════════════════
                    _buildHeader(),

                    Gap(48.h),

                    // ═══════════════════════════════════════
                    // EMAIL FIELD
                    // ═══════════════════════════════════════
                    _buildEmailField()
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideX(begin: -0.1, end: 0),

                    Gap(16.h),

                    // ═══════════════════════════════════════
                    // PASSWORD FIELD
                    // ═══════════════════════════════════════
                    _buildPasswordField()
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideX(begin: -0.1, end: 0),

                    Gap(12.h),

                    // ═══════════════════════════════════════
                    // REMEMBER ME + FORGOT PASSWORD
                    // ═══════════════════════════════════════
                    _buildRememberForgot()
                        .animate()
                        .fadeIn(delay: 400.ms),

                    Gap(32.h),

                    // ═══════════════════════════════════════
                    // LOGIN BUTTON
                    // ═══════════════════════════════════════
                    CustomButton(
                      label: 'Login',
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                      gradient: AppColors.adminGradient,
                    )
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideY(begin: 0.2, end: 0),

                    Gap(24.h),

                    // ═══════════════════════════════════════
                    // DIVIDER
                    // ═══════════════════════════════════════
                    _buildDivider()
                        .animate()
                        .fadeIn(delay: 600.ms),

                    Gap(24.h),

                    // ═══════════════════════════════════════
                    // REGISTER LINK
                    // ═══════════════════════════════════════
                    _buildRegisterLink()
                        .animate()
                        .fadeIn(delay: 700.ms),

                    Gap(40.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // BUILD METHODS
  // ═══════════════════════════════════════

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo Icon
        Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            gradient: AppColors.adminGradient,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.adminPrimary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.inventory_2_rounded,
            color: AppColors.white,
            size: 30.sp,
          ),
        )
            .animate()
            .scale(duration: 500.ms, curve: Curves.elasticOut)
            .fadeIn(),

        Gap(24.h),

        Text(
          'Welcome Back! 👋',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms)
            .slideY(begin: 0.3, end: 0),

        Gap(8.h),

        Text(
          'Login to manage your products\nand price catalog',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        )
            .animate()
            .fadeIn(delay: 150.ms)
            .slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
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
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                .hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: Icon(
              Iconsax.lock,
              size: 20.sp,
              color: AppColors.textHint,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                size: 20.sp,
                color: AppColors.textHint,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRememberForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                activeColor: AppColors.adminPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            Gap(8.w),
            Text(
              'Remember me',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: _handleForgotPassword,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.adminPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.border, thickness: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'New to PriceCatalog?',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textHint,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.border, thickness: 1),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: OutlinedButton(
            onPressed: () => context.push(AppRoutes.register),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: AppColors.adminPrimary,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Register as Trader',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.adminPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}