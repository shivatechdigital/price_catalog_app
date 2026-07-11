import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';
import 'package:price_catalog_app/data/models/category_model.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';
import 'package:price_catalog_app/providers/category_provider.dart';
import 'package:price_catalog_app/shared/widgets/custom_button.dart';
import 'package:price_catalog_app/shared/widgets/custom_snackbar.dart';
import 'package:uuid/uuid.dart';

// ═══════════════════════════════════════
// EMOJI ICONS FOR CATEGORIES
// ═══════════════════════════════════════
const List<String> _categoryIcons = [
  '🔩', '🏗️', '⚡', '🪵', '🔧', '🏠', '🚿',
  '🎨', '🔑', '🪟', '🚪', '🏺', '🪨', '🔌',
  '💡', '🔦', '🪜', '🛠️', '⚙️', '🧱', '📦',
  '🚰', '🔥', '❄️', '🌿', '🏭', '🚛', '⚖️',
];

class AddEditCategorySheet extends ConsumerStatefulWidget {
  final CategoryModel? category;

  const AddEditCategorySheet({super.key, this.category});

  bool get isEditing => category != null;

  @override
  ConsumerState<AddEditCategorySheet> createState() =>
      _AddEditCategorySheetState();
}

class _AddEditCategorySheetState
    extends ConsumerState<AddEditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _subCategoryController = TextEditingController();

  String _selectedIcon = '📦';
  bool _isLoading = false;
  List<SubCategoryModel> _subCategories = [];
  String _subCategoryIcon = '🔧';

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _nameController.text = widget.category!.name;
      _descController.text = widget.category!.description;
      _selectedIcon = widget.category!.icon;
      _subCategories =
          List.from(widget.category!.subCategories);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _subCategoryController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // SAVE CATEGORY
  // ═══════════════════════════════════════
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final currentUser = ref.read(currentUserProvider);

    bool success;

    if (widget.isEditing) {
      success = await ref
          .read(categoryNotifierProvider.notifier)
          .updateCategory(
            categoryId: widget.category!.id,
            name: _nameController.text,
            description: _descController.text,
            icon: _selectedIcon,
            subCategories: _subCategories,
          );
    } else {
      // Get current category count for sort order
        final categories =
          ref.read(categoriesStreamProvider).asData?.value ?? [];

      success = await ref
          .read(categoryNotifierProvider.notifier)
          .addCategory(
            name: _nameController.text,
            description: _descController.text,
            icon: _selectedIcon,
            sortOrder: categories.length + 1,
            createdBy: currentUser?.uid ?? '',
            subCategories: _subCategories,
          );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      CustomSnackbar.showSuccess(
        context,
        widget.isEditing
            ? 'Category updated successfully!'
            : 'Category added successfully!',
      );
    } else {
      CustomSnackbar.showError(
        context,
        'Failed to save category. Please try again.',
      );
    }
  }

  // ═══════════════════════════════════════
  // ADD SUBCATEGORY
  // ═══════════════════════════════════════
  void _addSubCategory() {
    final name = _subCategoryController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _subCategories.add(
        SubCategoryModel(
          id: const Uuid().v4(),
          name: name,
          icon: _subCategoryIcon,
        ),
      );
      _subCategoryController.clear();
    });
  }

  // ═══════════════════════════════════════
  // REMOVE SUBCATEGORY
  // ═══════════════════════════════════════
  void _removeSubCategory(String id) {
    setState(() {
      _subCategories.removeWhere((s) => s.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24.r),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                // ═══════════════════════════════════════
                // DRAG HANDLE + HEADER
                // ═══════════════════════════════════════
                _buildHeader(),

                // ═══════════════════════════════════════
                // CONTENT
                // ═══════════════════════════════════════
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Gap(8.h),

                        // ICON PICKER
                        _buildIconPicker(),

                        Gap(20.h),

                        // CATEGORY NAME
                        _buildLabel('Category Name *'),
                        Gap(8.h),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'e.g. Iron & Steel',
                            prefixIcon: Icon(
                              Iconsax.category,
                              size: 20.sp,
                              color: AppColors.textHint,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Category name is required';
                            }
                            if (v.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),

                        Gap(16.h),

                        // DESCRIPTION
                        _buildLabel('Description'),
                        Gap(8.h),
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                'Brief description about this category...',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 40.h),
                              child: Icon(
                                Iconsax.document_text,
                                size: 20.sp,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                        ),

                        Gap(24.h),

                        // SUBCATEGORIES SECTION
                        _buildSubCategoriesSection(),

                        Gap(32.h),
                      ],
                    ),
                  ),
                ),

                // ═══════════════════════════════════════
                // SAVE BUTTON
                // ═══════════════════════════════════════
                _buildSaveButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════
  Widget _buildHeader() {
    return Column(
      children: [
        Gap(12.h),
        Container(
          width: 40.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        Gap(16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              // Icon preview
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  gradient: AppColors.adminGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    _selectedIcon,
                    style: TextStyle(fontSize: 22.sp),
                  ),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEditing
                          ? 'Edit Category'
                          : 'New Category',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.isEditing
                          ? 'Update category details'
                          : 'Add a new product category',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Gap(16.h),
        const Divider(height: 1),
        Gap(16.h),
      ],
    );
  }

  // ═══════════════════════════════════════
  // ICON PICKER
  // ═══════════════════════════════════════
  Widget _buildIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Choose Icon'),
        Gap(10.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.border),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(12.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
            ),
            itemCount: _categoryIcons.length,
            itemBuilder: (context, index) {
              final icon = _categoryIcons[index];
              final isSelected = icon == _selectedIcon;

              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.adminPrimary
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.adminPrimary
                          : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.adminPrimary
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: TextStyle(fontSize: 18.sp),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // SUBCATEGORIES SECTION
  // ═══════════════════════════════════════
  Widget _buildSubCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Sub Categories'),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 4.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.adminPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${_subCategories.length} added',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.adminPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        Gap(10.h),

        // Add Sub Category Row
        Row(
          children: [
            // Sub category icon picker
            GestureDetector(
              onTap: _showSubCategoryIconPicker,
              child: Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    _subCategoryIcon,
                    style: TextStyle(fontSize: 22.sp),
                  ),
                ),
              ),
            ),

            Gap(10.w),

            // Sub category name input
            Expanded(
              child: TextField(
                controller: _subCategoryController,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _addSubCategory(),
                decoration: InputDecoration(
                  hintText: 'Sub category name...',
                  suffixIcon: IconButton(
                    onPressed: _addSubCategory,
                    icon: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        gradient: AppColors.adminGradient,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: AppColors.white,
                        size: 18.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        Gap(12.h),

        // Sub categories list
        if (_subCategories.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: _subCategories.asMap().entries.map((entry) {
                final index = entry.key;
                final sub = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      child: Row(
                        children: [
                          Text(
                            sub.icon,
                            style: TextStyle(fontSize: 20.sp),
                          ),
                          Gap(10.w),
                          Expanded(
                            child: Text(
                              sub.name,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          // Drag handle
                          Icon(
                            Icons.drag_indicator_rounded,
                            size: 20.sp,
                            color: AppColors.textHint,
                          ),
                          Gap(8.w),
                          // Delete button
                          GestureDetector(
                            onTap: () =>
                                _removeSubCategory(sub.id),
                            child: Container(
                              width: 28.w,
                              height: 28.w,
                              decoration: BoxDecoration(
                                color: AppColors.rejectedLight,
                                borderRadius:
                                    BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14.sp,
                                color: AppColors.rejected,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < _subCategories.length - 1)
                      const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, end: 0),
      ],
    );
  }

  // ═══════════════════════════════════════
  // SUB CATEGORY ICON PICKER
  // ═══════════════════════════════════════
  void _showSubCategoryIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20.r),
          ),
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
              'Choose Icon',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Gap(16.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8.w,
                mainAxisSpacing: 8.h,
              ),
              itemCount: _categoryIcons.length,
              itemBuilder: (context, index) {
                final icon = _categoryIcons[index];
                return GestureDetector(
                  onTap: () {
                    setState(() => _subCategoryIcon = icon);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _subCategoryIcon == icon
                          ? AppColors.adminPrimary.withOpacity(0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: _subCategoryIcon == icon
                            ? AppColors.adminPrimary
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: TextStyle(fontSize: 20.sp),
                      ),
                    ),
                  ),
                );
              },
            ),
            Gap(20.h),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // SAVE BUTTON
  // ═══════════════════════════════════════
  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: CustomButton(
        label: widget.isEditing
            ? 'Update Category'
            : 'Add Category',
        isLoading: _isLoading,
        gradient: AppColors.adminGradient,
        prefixIcon: widget.isEditing
            ? Iconsax.edit
            : Icons.add_rounded,
        onPressed: _save,
      ),
    );
  }

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
}