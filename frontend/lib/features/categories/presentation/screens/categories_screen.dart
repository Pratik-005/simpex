import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/currency_constants.dart';
import '../../../../core/injection/init_dependencies.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/repositories/category_repository.dart';
import '../../domain/models/category.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final List<Category> _categories = List.from(CategoryRepository.instance.categories);
  bool _isAlphabetical = false;
  // ignore: unused_field
  String _currencySymbol = '₹';

  @override
  void initState() {
    super.initState();
    CategoryRepository.instance.categoriesNotifier.addListener(_onRepoCategoriesChanged);
    try {
      if (sl.isRegistered<AuthStorage>()) {
        final user = sl<AuthStorage>().getUser();
        if (user != null && user.currency.isNotEmpty) {
          _currencySymbol = CurrencyConstants.getSymbol(user.currency);
        }
      }
    } catch (_) {}
    _fetchCategories();
  }

  void _onRepoCategoriesChanged() {
    if (!mounted) return;
    setState(() {
      _categories.clear();
      _categories.addAll(CategoryRepository.instance.categories);
    });
  }

  @override
  void dispose() {
    CategoryRepository.instance.categoriesNotifier.removeListener(_onRepoCategoriesChanged);
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    await CategoryRepository.instance.fetchCategories(forceRefresh: true);
  }

  List<Category> get _displayCategories {
    final list = List<Category>.from(_categories);
    if (_isAlphabetical) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  Future<void> _handleCreateCategory(
    String name,
    IconData icon,
    Color color,
  ) async {
    try {
      await CategoryRepository.instance.createCategory(
        name: name,
        color: color,
        icon: icon,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$name" created'),
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create category: $e'),
            backgroundColor: AppColors.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _handleUpdateCategory(
    Category oldCat,
    String name,
    IconData icon,
    Color color,
  ) async {
    try {
      await CategoryRepository.instance.updateCategory(
        categoryId: oldCat.id,
        name: name,
        color: color,
        icon: icon,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$name" updated'),
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update category: $e'),
            backgroundColor: AppColors.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteCategory(Category cat) async {
    final removedName = cat.name;
    try {
      await CategoryRepository.instance.deleteCategory(cat.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$removedName" deleted'),
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete category: $e'),
            backgroundColor: AppColors.errorContainer,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmDialog(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Category',
                style: AppTypography.headlineSm.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${cat.name}"? This action cannot be undone.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Delete',
                  variant: AppButtonVariant.danger,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleDeleteCategory(cat);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCategoryModal({Category? categoryToEdit}) {
    final isEditing = categoryToEdit != null;
    final nameController = TextEditingController(
      text: categoryToEdit?.name ?? '',
    );
    IconData selectedIcon =
        categoryToEdit?.icon ?? Icons.fitness_center_outlined;
    Color selectedColor = categoryToEdit?.color ?? const Color(0xFF4EDEA3);
    String? nameError;

    final availableIcons = <IconData>[
      Icons.fitness_center_outlined,
      Icons.pets_outlined,
      Icons.menu_book_outlined,
      Icons.flight_outlined,
      Icons.card_giftcard_outlined,
      Icons.sports_esports_outlined,
      Icons.restaurant_rounded,
      Icons.shopping_bag_outlined,
      Icons.bolt_outlined,
      Icons.directions_car_outlined,
      Icons.medical_services_outlined,
      Icons.subscriptions_outlined,
      Icons.school_outlined,
      Icons.savings_outlined,
      Icons.home_outlined,
      Icons.local_cafe_outlined,
      Icons.movie_outlined,
      Icons.work_outline,
    ];

    final availableColors = <Color>[
      const Color(0xFF4EDEA3), // Emerald (Primary)
      const Color(0xFFC0C1FF), // Celestial Violet (Secondary)
      const Color(0xFFFFB95F), // Amber (Tertiary)
      const Color(0xFF38BDF8), // Sky Blue
      const Color(0xFFFFB4AB), // Rose (Error)
      const Color(0xFF2DD4BF), // Teal
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pull Indicator
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.outline.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Sheet Header
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                (isEditing ? selectedColor : AppColors.primary)
                                    .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              isEditing ? selectedIcon : Icons.category_rounded,
                              size: 18,
                              color: isEditing
                                  ? selectedColor
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isEditing ? 'Edit Category' : 'Create New Category',
                          style: AppTypography.headlineSm.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => Navigator.of(ctx).pop(),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Field 1: Category Name (Matching App Input Field Style)
                    AppTextField(
                      controller: nameController,
                      label: 'Category Name',
                      hintText: 'e.g., Gym & Fitness, Pet Care',
                      prefixIcon: Icons.category_outlined,
                      onChanged: (_) {
                        if (nameError != null) {
                          setModalState(() => nameError = null);
                        }
                      },
                    ),
                    if (nameError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 14,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                nameError!,
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Field 2: Icon Picker (Choose Symbol) - Inside circle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Choose Symbol',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${availableIcons.length} available',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: availableIcons.map((ic) {
                        final isSelected = ic == selectedIcon;
                        return InkWell(
                          onTap: () => setModalState(() => selectedIcon = ic),
                          customBorder: const CircleBorder(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor.withValues(alpha: 0.18)
                                  : AppColors.surfaceContainerLow.withValues(
                                      alpha: 0.9,
                                    ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? selectedColor
                                    : AppColors.outlineVariant.withValues(
                                        alpha: 0.4,
                                      ),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                ic,
                                size: 20,
                                color: isSelected
                                    ? selectedColor
                                    : AppColors.outline,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Field 3: Accent Tint - Inside circle
                    Text(
                      'Accent Tint',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: availableColors.map((col) {
                        final isSelected = col == selectedColor;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            onTap: () =>
                                setModalState(() => selectedColor = col),
                            customBorder: const CircleBorder(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: col,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: col.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.black87,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Cancel',
                            variant: AppButtonVariant.outline,
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: isEditing ? 'Save' : 'Save',
                            onPressed: () {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                setModalState(
                                  () => nameError = 'Category name is required',
                                );
                                return;
                              }

                              Navigator.of(ctx).pop();
                              if (isEditing) {
                                _handleUpdateCategory(
                                  categoryToEdit,
                                  name,
                                  selectedIcon,
                                  selectedColor,
                                );
                              } else {
                                _handleCreateCategory(
                                  name,
                                  selectedIcon,
                                  selectedColor,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _displayCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Categories',
        showBackButton: true,
        onBack: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primary,
              size: 26,
            ),
            tooltip: 'Add Category',
            onPressed: () => _showCategoryModal(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Summary Card: Total Category Allocation
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Ambient emerald glow top-right
                  Positioned(
                    right: -16,
                    top: -16,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.category_outlined,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CATEGORY DIRECTORY',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 1.2,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_categories.length} Categories',
                          style: AppTypography.headlineLg.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                            fontSize: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 2. Category List Breakdown Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: AppTypography.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.onSurface,
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isAlphabetical = !_isAlphabetical;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isAlphabetical ? 'Alphabetical' : 'Default',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.swap_vert,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Category Cards List with circular icons and circular edit/delete options
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showCategoryModal(categoryToEdit: cat),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          // Left: Tinted Icon inside Circle
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cat.color.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(cat.icon, size: 22, color: cat.color),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Center: Category Name
                          Expanded(
                            child: Text(
                              cat.name,
                              style: AppTypography.titleMd.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Action: Edit Category Icon inside Circle
                          InkWell(
                            onTap: () =>
                                _showCategoryModal(categoryToEdit: cat),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 17,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Action: Delete Category Icon inside Circle
                          InkWell(
                            onTap: () => _showDeleteConfirmDialog(cat),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.error.withValues(
                                    alpha: 0.35,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 17,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
