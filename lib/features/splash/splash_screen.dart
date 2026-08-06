import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;
  Timer? _fallbackTimer;
  ProviderSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _listenAuthState();
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _hasNavigated) return;
      if (context.mounted) {
        context.go(AppRoutes.login);
        _hasNavigated = true;
      }
    });
  }

  void _listenAuthState() {
    _authSubscription = ref.listenManual<AuthState>(
      authStateProvider,
      (previous, next) {
        if (_hasNavigated) return;
        _navigateForState(next);
      },
      fireImmediately: true,
    );
  }

  void _navigateForState(AuthState authState) {
    if (!mounted) return;
    authState.when(
      initial: () => null,
      loading: () => null,
      unauthenticated: () {
        _navigateAfterDelay(AppRoutes.login);
      },
      profileIncomplete: () {
        _navigateAfterDelay(AppRoutes.completeProfile);
      },
      pendingApproval: () {
        _navigateAfterDelay(AppRoutes.pendingApproval);
      },
      authenticatedAdmin: (_) {
        _navigateAfterDelay(AppRoutes.adminDashboard);
      },
      authenticatedTrader: (_) {
        _navigateAfterDelay(AppRoutes.traderDashboard);
      },
    );
  }

  void _navigateAfterDelay(String route) {
    if (_hasNavigated) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _hasNavigated) return;
      context.go(route);
      _hasNavigated = true;
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _authSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildSplashUI(context);
  }

  Widget _buildSplashUI(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF283593),
              Color(0xFF3949AB),
              Color(0xFF5C6BC0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ═══════════════════════════════════════
              // APP ICON
              // ═══════════════════════════════════════
              Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      color: AppColors.white.withAlpha(38),
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(
                        color: AppColors.white.withAlpha(76),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms),

              SizedBox(height: 28.h),

              // ═══════════════════════════════════════
              // APP NAME (download/install name)
              // ═══════════════════════════════════════
              Text(
                    'Shri Anandeshwar Traders',
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white.withAlpha(230),
                      letterSpacing: -0.5,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              SizedBox(height: 8.h),

              Text(
                    'Smart Price & Catalog Management',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.white.withAlpha(191),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              const Spacer(flex: 2),

              // ═══════════════════════════════════════
              // LOADING INDICATOR
              // ═══════════════════════════════════════
              SizedBox(
                width: 36.w,
                height: 36.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.white.withAlpha(153),
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms, duration: 400.ms),

              SizedBox(height: 48.h),

              // ═══════════════════════════════════════
              // VERSION
              // ═══════════════════════════════════════
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.white.withAlpha(102),
                ),
              ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
