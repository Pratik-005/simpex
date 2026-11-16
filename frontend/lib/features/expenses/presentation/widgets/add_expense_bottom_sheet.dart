import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/currency_constants.dart';
import '../../../../core/injection/init_dependencies.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/domain/models/category.dart';
import '../../data/mock_expense_repository.dart';

class AddExpenseBottomSheet extends StatefulWidget {
  const AddExpenseBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseBottomSheet(),
    );
  }

  @override
  State<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<AddExpenseBottomSheet> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();
  final _categorySearchController = TextEditingController();

  String _currencyCode = 'INR';
  String _currencySymbol = '₹';

  List<Category> _allCategories = List.from(CategoryRepository.instance.categories);
  late Category _selectedCategory;
  bool _isCategoryDropdownOpen = false;
  String _categorySearchQuery = '';
  bool _isLoadingCategories = false;

  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'UPI';
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'UPI',
    'Credit Card',
    'Debit Card',
    'Cash',
    'Apple Pay',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _allCategories.isNotEmpty
        ? _allCategories.first
        : Category.defaults.first;

    CategoryRepository.instance.categoriesNotifier.addListener(_onCategoriesChanged);
    CategoryRepository.instance.isLoadingNotifier.addListener(_onCategoryLoadingChanged);

    _loadUserCurrency();
    _fetchCategories();
  }

  void _onCategoriesChanged() {
    if (!mounted) return;
    final updated = CategoryRepository.instance.categories;
    if (updated.isNotEmpty) {
      setState(() {
        _allCategories = updated;
        final existingIndex =
            _allCategories.indexWhere((c) => c.id == _selectedCategory.id);
        if (existingIndex >= 0) {
          _selectedCategory = _allCategories[existingIndex];
        } else {
          _selectedCategory = _allCategories.first;
        }
      });
    }
  }

  void _onCategoryLoadingChanged() {
    if (mounted) {
      setState(() {
        _isLoadingCategories =
            CategoryRepository.instance.isLoadingNotifier.value;
      });
    }
  }

  void _loadUserCurrency() {
    try {
      if (sl.isRegistered<AuthStorage>()) {
        final user = sl<AuthStorage>().getUser();
        if (user != null && user.currency.isNotEmpty) {
          final item = CurrencyConstants.find(user.currency);
          setState(() {
            _currencyCode = item.code;
            _currencySymbol = item.symbol;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchCategories({bool forceRefresh = false}) async {
    await CategoryRepository.instance.fetchCategories(forceRefresh: forceRefresh);
  }

  List<Category> get _filteredCategories {
    if (_categorySearchQuery.isEmpty) return _allCategories;
    return _allCategories
        .where(
          (c) => c.name.toLowerCase().contains(_categorySearchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    CategoryRepository.instance.categoriesNotifier.removeListener(_onCategoriesChanged);
    CategoryRepository.instance.isLoadingNotifier.removeListener(_onCategoryLoadingChanged);
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    _categorySearchController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final amountText = _amountController.text.trim().replaceAll(',', '');
    final double? parsedAmount = double.tryParse(amountText);

    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than zero.'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
      return;
    }

    final merchant = _merchantController.text.trim();
    if (merchant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a merchant or description.'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
      return;
    }

    final int amountPaise = CurrencyFormatter.rupeesToPaise(parsedAmount);

    setState(() => _isLoading = true);

    try {
      await MockExpenseRepository.instance.addExpense(
        merchant: merchant,
        categoryId: _selectedCategory.id,
        categoryName: _selectedCategory.name,
        amountPaise: amountPaise,
        date: _selectedDate,
        paymentMethod: _selectedPaymentMethod,
        currency: _currencyCode,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Expense of $_currencySymbol$amountText recorded successfully!',
            ),
            backgroundColor: AppColors.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: $e'),
            backgroundColor: AppColors.errorContainer,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: bottomInset + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add New Transaction',
                  style: AppTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount Input with default user currency symbol & code
            AppTextField(
              controller: _amountController,
              label: 'Amount ($_currencyCode)',
              hintText: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIconWidget: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(left: 12, right: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _currencySymbol,
                    style: AppTypography.titleMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Merchant description
            AppTextField(
              controller: _merchantController,
              label: 'Merchant / Description',
              hintText: 'e.g. Whole Foods, Swiggy, Uber',
              prefixIcon: Icons.storefront,
            ),
            const SizedBox(height: 16),

            // Category selector (Searchable Dropdown)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    'Category',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_isLoadingCategories)
                  const Padding(
                    padding: EdgeInsets.only(right: 6, bottom: 6),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: () => _fetchCategories(forceRefresh: true),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sync_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Refresh',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Dropdown trigger
            InkWell(
              onTap: () {
                final willOpen = !_isCategoryDropdownOpen;
                setState(() {
                  _isCategoryDropdownOpen = willOpen;
                  if (!willOpen) {
                    _categorySearchQuery = '';
                    _categorySearchController.clear();
                  }
                });
                if (willOpen) {
                  _fetchCategories();
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isCategoryDropdownOpen
                        ? AppColors.primary
                        : AppColors.outlineVariant.withValues(alpha: 0.4),
                    width: _isCategoryDropdownOpen ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Selected category circular icon badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _selectedCategory.color.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedCategory.color.withValues(alpha: 0.45),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _selectedCategory.icon,
                          size: 18,
                          color: _selectedCategory.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCategory.name,
                        style: AppTypography.bodyLg.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      _isCategoryDropdownOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _isCategoryDropdownOpen
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            // Dropdown Menu popup with Search
            if (_isCategoryDropdownOpen) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar
                    AppTextField(
                      controller: _categorySearchController,
                      hintText: 'Search categories...',
                      prefixIcon: Icons.search,
                      onChanged: (val) {
                        setState(() => _categorySearchQuery = val.trim());
                      },
                    ),
                    const SizedBox(height: 8),

                    // Filtered list
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: _isLoadingCategories && _filteredCategories.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Fetching categories from server...',
                                      style: AppTypography.bodySm.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _filteredCategories.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _categorySearchQuery.isNotEmpty
                                              ? 'No matching categories'
                                              : 'No categories available',
                                          style: AppTypography.bodyMd.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed: () => _fetchCategories(forceRefresh: true),
                                          icon: const Icon(
                                            Icons.refresh,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                          label: const Text(
                                            'Retry',
                                            style: TextStyle(color: AppColors.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _filteredCategories.length,
                              separatorBuilder: (_, _) => const Divider(
                                color: AppColors.cardBorder,
                                height: 1,
                              ),
                              itemBuilder: (ctx, index) {
                                final cat = _filteredCategories[index];
                                final isSelected =
                                    cat.id == _selectedCategory.id;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = cat;
                                      _isCategoryDropdownOpen = false;
                                      _categorySearchQuery = '';
                                      _categorySearchController.clear();
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                              .withValues(alpha: 0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        // Circular Icon
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: cat.color
                                                .withValues(alpha: 0.16),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: cat.color
                                                  .withValues(alpha: 0.4),
                                              width: 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              cat.icon,
                                              size: 16,
                                              color: cat.color,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            cat.name,
                                            style:
                                                AppTypography.bodyMd.copyWith(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textPrimary,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Payment method selector
            Text(
              'Payment Method',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _paymentMethods.map((method) {
                  final isSelected = method == _selectedPaymentMethod;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedPaymentMethod = method);
                        }
                      },
                      label: Text(method),
                      labelStyle: AppTypography.labelSm.copyWith(
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: AppColors.surfaceContainerLow,
                      selectedColor: AppColors.primary,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.outlineVariant
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Date picker trigger
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primary,
                          onPrimary: AppColors.onPrimary,
                          surface: AppColors.surfaceContainerHigh,
                          onSurface: AppColors.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            AppButton(
              label: 'Save Expense',
              icon: Icons.check,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _onSave,
            ),
          ],
        ),
      ),
    );
  }
}
