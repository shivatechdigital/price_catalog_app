import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final double? height;
  final double? fontSize;
  final IconData? prefixIcon;
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.backgroundColor,
    this.height,
    this.fontSize,
    this.prefixIcon,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height ?? 52.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isOutlined ? null : gradient,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: (gradient != null && !isOutlined && onPressed != null)
              ? [
                  BoxShadow(
                    color: (gradient?.colors.first ?? AppColors.adminPrimary)
                        .withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                gradient != null ? Colors.transparent : backgroundColor,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: isOutlined
                  ? const BorderSide(color: AppColors.adminPrimary, width: 1.5)
                  : BorderSide.none,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (prefixIcon != null) ...[
                      Icon(prefixIcon, size: 20.sp, color: AppColors.white),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize ?? 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isOutlined
                            ? AppColors.adminPrimary
                            : AppColors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}