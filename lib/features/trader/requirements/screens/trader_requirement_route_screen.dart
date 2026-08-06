import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/features/trader/requirements/screens/trader_requirement_detail_screen.dart';
import 'package:price_catalog_app/providers/requirement_provider.dart';

/// Route wrapper that loads a requirement by its ID (used when navigating
/// from a notification where only the [NotificationModel.referenceId] is
/// available) and then renders the full [TraderRequirementDetailScreen].
class TraderRequirementRouteScreen extends ConsumerWidget {
  final String requirementId;

  const TraderRequirementRouteScreen({super.key, required this.requirementId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirementAsync = ref.watch(requirementByIdProvider(requirementId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Requirement',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: requirementAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.traderPrimary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.warning_2, size: 48.sp, color: AppColors.rejected),
              Gap(16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  'Could not load this requirement.\nIt may have been removed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (requirement) {
          if (requirement == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.document_text,
                    size: 48.sp,
                    color: AppColors.textHint,
                  ),
                  Gap(16.h),
                  Text(
                    'Requirement not found',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }
          return TraderRequirementDetailScreen(requirement: requirement);
        },
      ),
    );
  }
}
