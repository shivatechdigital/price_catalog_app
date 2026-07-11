import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';

class CounterOfferDialog extends StatefulWidget {
  final RequirementModel requirement;
  final Function(double price, String? note) onCounter;

  const CounterOfferDialog({
    super.key,
    required this.requirement,
    required this.onCounter,
  });

  @override
  State<CounterOfferDialog> createState() =>
      _CounterOfferDialogState();
}

class _CounterOfferDialogState extends State<CounterOfferDialog> {
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.requirement;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: AppColors.counterLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.compare_arrows_rounded,
                    color: AppColors.counter,
                    size: 22.sp,
                  ),
                ),
                Gap(12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Counter Offer',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      req.productName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Gap(16.h),

            // Reference Prices
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                children: [
                  _refPriceRow(
                    'Customer Demanded',
                    '₹${req.customerDemandedPrice.toStringAsFixed(0)}',
                    AppColors.pending,
                  ),
                  Gap(6.h),
                  _refPriceRow(
                    'Trader Offered',
                    '₹${req.traderOfferedPrice.toStringAsFixed(0)}',
                    AppColors.adminPrimary,
                  ),
                  Gap(6.h),
                  _refPriceRow(
                    'Current Price',
                    '₹${req.productCurrentPrice.toStringAsFixed(0)}',
                    AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            Gap(16.h),

            // Counter Price
            Text(
              'Your Counter Price (₹) *',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Gap(8.h),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter your counter price',
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.counter,
                ),
                prefixIcon: Icon(
                  Iconsax.money,
                  size: 20.sp,
                  color: AppColors.textHint,
                ),
              ),
            ),

            Gap(14.h),

            // Note
            Text(
              'Note for Trader (Optional)',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Gap(8.h),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Explain your counter offer...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 28.h),
                  child: Icon(
                    Iconsax.note_text,
                    size: 20.sp,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),

            Gap(24.h),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.border),
                      padding:
                          EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            final price = double.tryParse(
                              _priceController.text,
                            );
                            if (price == null || price <= 0) {
                              return;
                            }
                            setState(() => _isLoading = true);
                            widget.onCounter(
                              price,
                              _noteController.text.trim().isEmpty
                                  ? null
                                  : _noteController.text.trim(),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.counter,
                      padding:
                          EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child:
                                const CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Send Counter 🔄',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _refPriceRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}